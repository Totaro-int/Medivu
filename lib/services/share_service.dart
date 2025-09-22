import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/report_model.dart';

class ShareService {
  static ShareService? _instance;
  
  ShareService._internal();
  
  static ShareService get instance {
    _instance ??= ShareService._internal();
    return _instance!;
  }

  /// 리포트를 공유합니다
  Future<void> shareReport(ReportModel report, {String? customMessage}) async {
    try {
      // PDF가 있으면 PDF와 함께 공유, 없으면 텍스트로만 공유
      if (report.hasPdf && report.pdfPath != null) {
        await _shareReportWithPDF(report, customMessage);
      } else {
        await _shareReportAsText(report, customMessage);
      }
    } catch (e) {
      throw Exception('리포트 공유 실패: $e');
    }
  }

  /// PDF 파일과 함께 리포트 공유
  Future<void> _shareReportWithPDF(ReportModel report, String? customMessage) async {
    try {
      final shareText = _generateShareText(report, customMessage);
      
      // Android/iOS에서 파일 공유
      if (Platform.isAndroid || Platform.isIOS) {
        // share_plus 패키지 사용 (pubspec.yaml에 추가 필요)
        // await Share.shareXFiles(
        //   [XFile(report.pdfPath!)],
        //   text: shareText,
        //   subject: '소음 측정 리포트 - ${report.title}',
        // );
        
        // 임시로 텍스트만 공유 (실제 구현시 share_plus 패키지 필요)
        await _copyToClipboardAndNotify(shareText);
      } else {
        // 데스크톱에서는 클립보드로 복사
        await _copyToClipboardAndNotify(shareText);
      }
    } catch (e) {
      throw Exception('PDF 공유 실패: $e');
    }
  }

  /// 텍스트로만 리포트 공유
  Future<void> _shareReportAsText(ReportModel report, String? customMessage) async {
    try {
      final shareText = _generateShareText(report, customMessage);
      
      if (Platform.isAndroid || Platform.isIOS) {
        // 모바일에서는 시스템 공유창 사용
        // await Share.share(
        //   shareText,
        //   subject: '소음 측정 리포트 - ${report.title}',
        // );
        
        // 임시로 클립보드로 복사
        await _copyToClipboardAndNotify(shareText);
      } else {
        // 데스크톱에서는 클립보드로 복사
        await _copyToClipboardAndNotify(shareText);
      }
    } catch (e) {
      throw Exception('텍스트 공유 실패: $e');
    }
  }

  /// 공유용 텍스트 생성
  String _generateShareText(ReportModel report, String? customMessage) {
    final buffer = StringBuffer();
    
    // 커스텀 메시지
    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln(customMessage);
      buffer.writeln();
    }
    
    // 리포트 제목
    buffer.writeln('📋 ${report.title.isNotEmpty ? report.title : "소음 측정 리포트"}');
    buffer.writeln();
    
    // 측정 정보
    buffer.writeln('📊 측정 정보');
    buffer.writeln('• 측정 일시: ${_formatDateTime(report.recording.startTime)}');
    if (report.recording.endTime != null) {
      buffer.writeln('• 측정 종료: ${_formatDateTime(report.recording.endTime!)}');
    }
    if (report.recording.duration != null) {
      buffer.writeln('• 측정 시간: ${_formatDuration(report.recording.duration!)}');
    }
    buffer.writeln();
    
    // 소음 데이터
    buffer.writeln('🔊 소음 측정 결과');
    buffer.writeln('• 최대 데시벨: ${report.recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB');
    buffer.writeln('• 최소 데시벨: ${report.recording.noiseData.minDecibel?.toStringAsFixed(1) ?? '0.0'}dB');
    buffer.writeln('• 평균 데시벨: ${report.recording.noiseData.avgDecibel?.toStringAsFixed(1) ?? '0.0'}dB');
    buffer.writeln('• 측정 횟수: ${report.recording.noiseData.measurementCount}회');
    buffer.writeln();
    
    // 위치 정보
    if (report.location != null || report.recording.location != null) {
      final location = report.location ?? report.recording.location!;
      buffer.writeln('📍 위치 정보');
      if (location.address != null) {
        buffer.writeln('• 주소: ${location.address}');
      }
      buffer.writeln('• 좌표: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}');
          buffer.writeln();
    }
    
    // 번호판 정보
    if (report.recording.hasLicensePlate) {
      buffer.writeln('🚗 번호판 정보');
      buffer.writeln('• 번호판: ${report.recording.licensePlate!.plateNumber}');
      if (report.recording.licensePlate!.confidence != null) {
        buffer.writeln('• 인식 신뢰도: ${(report.recording.licensePlate!.confidence! * 100).toStringAsFixed(1)}%');
      }
      buffer.writeln();
    }
    
    // 리포트 설명
    if (report.description.isNotEmpty) {
      buffer.writeln('📝 상세 내용');
      buffer.writeln(report.description);
      buffer.writeln();
    }
    
    // 상태 정보
    buffer.writeln('📋 리포트 상태: ${_getStatusText(report.status)}');
    if (report.complaintNumber != null) {
      buffer.writeln('📄 민원 번호: ${report.complaintNumber}');
    }
    buffer.writeln();
    
    // 앱 정보
    buffer.writeln('Generated by ActFinder');
    buffer.writeln('소음 측정 및 증거 수집 앱');
    
    return buffer.toString();
  }

  /// 클립보드에 복사하고 알림
  Future<void> _copyToClipboardAndNotify(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    // 알림은 호출하는 곳에서 처리
  }

  /// 이메일로 리포트 공유
  Future<void> shareReportByEmail(ReportModel report, {
    String? recipientEmail,
    String? customMessage,
  }) async {
    try {
      final subject = Uri.encodeComponent('소음 측정 리포트 - ${report.title}');
      final body = Uri.encodeComponent(_generateShareText(report, customMessage));
      
      final emailUrl = 'mailto:${recipientEmail ?? ''}?subject=$subject&body=$body';
      
      final uri = Uri.parse(emailUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('이메일 앱을 열 수 없습니다');
      }
    } catch (e) {
      throw Exception('이메일 공유 실패: $e');
    }
  }

  /// SMS로 리포트 공유 (요약본)
  Future<void> shareReportBySMS(ReportModel report, {
    String? phoneNumber,
    String? customMessage,
  }) async {
    try {
      final summary = _generateSMSSummary(report, customMessage);
      final body = Uri.encodeComponent(summary);
      
      final smsUrl = 'sms:${phoneNumber ?? ''}?body=$body';
      
      final uri = Uri.parse(smsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('SMS 앱을 열 수 없습니다');
      }
    } catch (e) {
      throw Exception('SMS 공유 실패: $e');
    }
  }

  /// SMS용 요약 텍스트 생성
  String _generateSMSSummary(ReportModel report, String? customMessage) {
    final buffer = StringBuffer();
    
    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.write('$customMessage ');
    }
    
    buffer.write('소음측정 결과: ');
    buffer.write('최대 ${report.recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB, ');
    buffer.write('평균 ${report.recording.noiseData.avgDecibel?.toStringAsFixed(1) ?? '0.0'}dB ');
    buffer.write('(${_formatDateTime(report.recording.startTime)})');
    
    if (report.recording.hasLicensePlate) {
      buffer.write(' 번호판: ${report.recording.licensePlate!.plateNumber}');
    }
    
    return buffer.toString();
  }

  /// 날짜 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 시간 포맷팅
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  /// 상태 텍스트
  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return '작성중';
      case ReportStatus.processing:
        return '처리중';
      case ReportStatus.ready:
        return '준비됨';
      case ReportStatus.submitted:
        return '제출됨';
      case ReportStatus.rejected:
        return '반려됨';
      case ReportStatus.approved:
        return '승인됨';
      default:
        return status.name;
    }
  }

  /// 공유 옵션 다이얼로그 표시용 데이터
  List<ShareOption> getShareOptions() {
    return [
      ShareOption(
        title: '텍스트로 공유',
        icon: 'text',
        description: '리포트 내용을 텍스트로 공유합니다',
        action: ShareAction.text,
      ),
      ShareOption(
        title: '이메일로 공유',
        icon: 'email',
        description: '이메일로 리포트를 전송합니다',
        action: ShareAction.email,
      ),
      ShareOption(
        title: 'SMS로 공유',
        icon: 'sms',
        description: '요약 내용을 SMS로 전송합니다',
        action: ShareAction.sms,
      ),
      if (Platform.isAndroid || Platform.isIOS)
        ShareOption(
          title: '시스템 공유',
          icon: 'system',
          description: '시스템 공유창을 사용합니다',
          action: ShareAction.system,
        ),
    ];
  }
}

/// 공유 옵션 클래스
class ShareOption {
  final String title;
  final String icon;
  final String description;
  final ShareAction action;

  ShareOption({
    required this.title,
    required this.icon,
    required this.description,
    required this.action,
  });
}

/// 공유 액션 타입
enum ShareAction {
  text,
  email,
  sms,
  system,
}