import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/recording_model.dart';
import '../models/report_model.dart';
import '../providers/enhanced_auth_provider.dart';
import '../utils/constants.dart';

class UploadService {
  static UploadService? _instance;
  
  UploadService._internal();
  
  static UploadService get instance {
    _instance ??= UploadService._internal();
    return _instance!;
  }

  /// 녹화 데이터를 로컬에 저장 (업로드 비활성화)
  Future<UploadResult> uploadRecording(RecordingModel recording) async {
    try {
      // 로컬 저장만 수행 - 서버 업로드 없음
      return UploadResult.success(
        '녹화 데이터가 로컬에 저장되었습니다',
        data: {
          'recording': recording.toMap(),
          'localOnly': true,
        },
      );
      
    } catch (e) {
      return UploadResult.error('로컬 저장 실패: $e');
    }
  }

  /// 리포트를 로컬에 저장 (업로드 비활성화)
  Future<UploadResult> uploadReport(ReportModel report) async {
    try {
      // 로컬 저장만 수행 - 서버 업로드 없음
      return UploadResult.success(
        '리포트가 로컬에 저장되었습니다',
        data: {
          'report': report.toMap(),
          'localOnly': true,
        },
      );
      
    } catch (e) {
      return UploadResult.error('로컬 저장 실패: $e');
    }
  }

  /// 파일 업로드 (비디오, PDF 등)
  Future<UploadResult> _uploadFile(
    String filePath,
    String fileType,
    String recordingId,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return UploadResult.error('파일이 존재하지 않습니다: $filePath');
      }

      final fileName = path.basename(filePath);
      final fileExtension = path.extension(filePath);
      
      // 멀티파트 요청 생성
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/upload/$fileType'),
      );

      // 인증 헤더 추가
      final authProvider = EnhancedAuthProvider.instance;
      if (authProvider.userId != null) {
        request.headers['Authorization'] = 'Bearer ${authProvider.userId}';
      }

      // 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: '${recordingId}_$fileType$fileExtension',
        ),
      );

      // 메타데이터 추가
      request.fields['recordingId'] = recordingId;
      request.fields['fileType'] = fileType;
      request.fields['originalName'] = fileName;
      request.fields['uploadTime'] = DateTime.now().toIso8601String();

      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UploadResult.success(
          '파일 업로드 성공',
          data: responseData,
        );
      } else {
        final errorData = json.decode(response.body);
        return UploadResult.error(
          errorData['message'] ?? '파일 업로드 실패',
        );
      }
      
    } catch (e) {
      return UploadResult.error('파일 업로드 오류: $e');
    }
  }

  /// 녹화 메타데이터 업로드
  Future<UploadResult> _uploadRecordingMetadata(RecordingModel recording) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.videosEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${EnhancedAuthProvider.instance.userId}',
        },
        body: json.encode(recording.toMap()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return UploadResult.success(
          '녹화 메타데이터 업로드 성공',
          data: responseData,
        );
      } else {
        final errorData = json.decode(response.body);
        return UploadResult.error(
          errorData['message'] ?? '메타데이터 업로드 실패',
        );
      }
      
    } catch (e) {
      return UploadResult.error('메타데이터 업로드 오류: $e');
    }
  }

  /// 리포트 메타데이터 업로드
  Future<UploadResult> _uploadReportMetadata(ReportModel report) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.reportsEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${EnhancedAuthProvider.instance.userId}',
        },
        body: json.encode(report.toMap()),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return UploadResult.success(
          '리포트 메타데이터 업로드 성공',
          data: responseData,
        );
      } else {
        final errorData = json.decode(response.body);
        return UploadResult.error(
          errorData['message'] ?? '리포트 업로드 실패',
        );
      }
      
    } catch (e) {
      return UploadResult.error('리포트 업로드 오류: $e');
    }
  }

  /// 업로드 진행률을 추적하며 파일 업로드 (대용량 파일용)
  Future<UploadResult> uploadFileWithProgress(
    String filePath,
    String fileType,
    String recordingId,
    Function(double progress)? onProgress,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return UploadResult.error('파일이 존재하지 않습니다: $filePath');
      }

      final fileSize = file.lengthSync();
      final fileName = path.basename(filePath);
      final fileExtension = path.extension(filePath);
      
      // HTTP 클라이언트 생성
      final client = http.Client();
      
      try {
        // 멀티파트 요청 생성
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConstants.baseUrl}/upload/$fileType'),
        );

        // 인증 헤더 추가
        final authProvider = EnhancedAuthProvider.instance;
        if (authProvider.userId != null) {
          request.headers['Authorization'] = 'Bearer ${authProvider.userId}';
        }

        // 파일 스트림 생성
        final fileStream = http.ByteStream(file.openRead());
        
        // 진행률 추적을 위한 스트림 래퍼
        var uploadedBytes = 0;
        final progressStream = fileStream.transform(
          StreamTransformer.fromHandlers(
            handleData: (List<int> data, EventSink<List<int>> sink) {
              uploadedBytes += data.length;
              final progress = uploadedBytes / fileSize;
              onProgress?.call(progress);
              sink.add(data);
            },
          ),
        );

        // 파일 추가
        request.files.add(
          http.MultipartFile(
            'file',
            progressStream,
            fileSize,
            filename: '${recordingId}_$fileType$fileExtension',
          ),
        );

        // 메타데이터 추가
        request.fields['recordingId'] = recordingId;
        request.fields['fileType'] = fileType;
        request.fields['originalName'] = fileName;
        request.fields['uploadTime'] = DateTime.now().toIso8601String();

        // 요청 전송
        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          return UploadResult.success(
            '파일 업로드 성공',
            data: responseData,
          );
        } else {
          final errorData = json.decode(response.body);
          return UploadResult.error(
            errorData['message'] ?? '파일 업로드 실패',
          );
        }
        
      } finally {
        client.close();
      }
      
    } catch (e) {
      return UploadResult.error('파일 업로드 오류: $e');
    }
  }

  /// 업로드 상태 확인
  Future<UploadResult> checkUploadStatus(String uploadId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/upload/status/$uploadId'),
        headers: {
          'Authorization': 'Bearer ${EnhancedAuthProvider.instance.userId}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return UploadResult.success(
          '상태 확인 성공',
          data: responseData,
        );
      } else {
        return UploadResult.error('상태 확인 실패');
      }
      
    } catch (e) {
      return UploadResult.error('상태 확인 오류: $e');
    }
  }

  /// 업로드 취소
  Future<UploadResult> cancelUpload(String uploadId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/upload/$uploadId'),
        headers: {
          'Authorization': 'Bearer ${EnhancedAuthProvider.instance.userId}',
        },
      );

      if (response.statusCode == 200) {
        return UploadResult.success('업로드가 취소되었습니다');
      } else {
        return UploadResult.error('업로드 취소 실패');
      }
      
    } catch (e) {
      return UploadResult.error('업로드 취소 오류: $e');
    }
  }
}

/// 업로드 결과 클래스
class UploadResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic> data;

  UploadResult._({
    required this.isSuccess,
    required this.message,
    this.data = const {},
  });

  factory UploadResult.success(String message, {Map<String, dynamic>? data}) {
    return UploadResult._(
      isSuccess: true,
      message: message,
      data: data ?? {},
    );
  }

  factory UploadResult.error(String message) {
    return UploadResult._(
      isSuccess: false,
      message: message,
    );
  }

  bool get isError => !isSuccess;

  @override
  String toString() {
    return 'UploadResult(isSuccess: $isSuccess, message: $message, data: $data)';
  }
}