import 'noise_data_model.dart';
import 'location_model.dart';
import 'license_plate_model.dart';

class RecordingModel {
  final String id;
  final String? videoPath;
  final String? videoUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final NoiseDataModel noiseData;
  final LocationModel? location;
  final LicensePlateModel? licensePlate;
  final String userId;
  final RecordingStatus status;
  final Map<String, dynamic>? metadata;

  const RecordingModel({
    required this.id,
    this.videoPath,
    this.videoUrl,
    required this.startTime,
    this.endTime,
    required this.noiseData,
    this.location,
    this.licensePlate,
    required this.userId,
    required this.status,
    this.metadata,
  });

  RecordingModel copyWith({
    String? id,
    String? videoPath,
    String? videoUrl,
    DateTime? startTime,
    DateTime? endTime,
    NoiseDataModel? noiseData,
    LocationModel? location,
    LicensePlateModel? licensePlate,
    String? userId,
    RecordingStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      noiseData: noiseData ?? this.noiseData,
      location: location ?? this.location,
      licensePlate: licensePlate ?? this.licensePlate,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  Duration? get duration {
    return endTime?.difference(startTime);
  }

  bool get isComplete => endTime != null && status == RecordingStatus.completed;
  bool get hasVideo => videoPath != null || videoUrl != null;
  bool get hasLicensePlate => licensePlate?.hasPlateNumber == true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'videoPath': videoPath,
      'videoUrl': videoUrl,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'noiseData': noiseData.toMap(),
      'location': location?.toMap(),
      'licensePlate': licensePlate?.toMap(),
      'userId': userId,
      'status': status.name,
      'metadata': metadata,
    };
  }

  static RecordingModel fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'] ?? '',
      videoPath: map['videoPath'],
      videoUrl: map['videoUrl'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      noiseData: NoiseDataModel.fromMap(map['noiseData']),
      location: map['location'] != null
          ? LocationModel.fromMap(map['location'])
          : null,
      licensePlate: map['licensePlate'] != null
          ? LicensePlateModel.fromMap(map['licensePlate'])
          : null,
      userId: map['userId'] ?? '',
      status: RecordingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RecordingStatus.draft,
      ),
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'RecordingModel(id: $id, status: $status, duration: $duration)';
  }
}

enum RecordingStatus {
  draft,
  recording,
  processing,
  completed,
  failed,
  uploaded,
}