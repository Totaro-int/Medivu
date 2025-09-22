import 'recording_model.dart';
import 'location_model.dart';

class ReportModel {
  final String id;
  final String title;
  final String description;
  final RecordingModel recording;
  final LocationModel? location;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String userId;
  final ReportStatus status;
  final String? pdfPath;
  final String? pdfUrl;
  final String? complaintNumber;
  final Map<String, dynamic>? metadata;

  const ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.recording,
    this.location,
    required this.createdAt,
    this.submittedAt,
    required this.userId,
    required this.status,
    this.pdfPath,
    this.pdfUrl,
    this.complaintNumber,
    this.metadata,
  });

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    RecordingModel? recording,
    LocationModel? location,
    DateTime? createdAt,
    DateTime? submittedAt,
    String? userId,
    ReportStatus? status,
    String? pdfPath,
    String? pdfUrl,
    String? complaintNumber,
    Map<String, dynamic>? metadata,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      recording: recording ?? this.recording,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      complaintNumber: complaintNumber ?? this.complaintNumber,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isSubmitted => submittedAt != null;
  bool get hasPdf => pdfPath != null || pdfUrl != null;
  bool get hasComplaintNumber => complaintNumber != null && complaintNumber!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recording': recording.toMap(),
      'location': location?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'submittedAt': submittedAt?.millisecondsSinceEpoch,
      'userId': userId,
      'status': status.name,
      'pdfPath': pdfPath,
      'pdfUrl': pdfUrl,
      'complaintNumber': complaintNumber,
      'metadata': metadata,
    };
  }

  static ReportModel fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      recording: RecordingModel.fromMap(map['recording']),
      location: map['location'] != null
          ? LocationModel.fromMap(map['location'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      submittedAt: map['submittedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['submittedAt'])
          : null,
      userId: map['userId'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.draft,
      ),
      pdfPath: map['pdfPath'],
      pdfUrl: map['pdfUrl'],
      complaintNumber: map['complaintNumber'],
      metadata: map['metadata'],
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, title: $title, status: $status)';
  }
}

enum ReportStatus {
  draft,
  processing,
  ready,
  submitted,
  rejected,
  approved,
}