class LicensePlateModel {
  final String id;
  final String? plateNumber;
  final String? imagePath;
  final DateTime? recognizedAt;
  final DateTime? detectedAt;
  final double? confidence;
  final String? rawText;
  final String? ocrProvider;
  final Map<String, dynamic>? ocrMetadata;
  final bool isValidFormat;

  const LicensePlateModel({
    required this.id,
    this.plateNumber,
    this.imagePath,
    this.recognizedAt,
    this.detectedAt,
    this.confidence,
    this.rawText,
    this.ocrProvider,
    this.ocrMetadata,
    required this.isValidFormat,
  });

  LicensePlateModel copyWith({
    String? id,
    String? plateNumber,
    String? imagePath,
    DateTime? recognizedAt,
    DateTime? detectedAt,
    double? confidence,
    String? rawText,
    String? ocrProvider,
    Map<String, dynamic>? ocrMetadata,
    bool? isValidFormat,
  }) {
    return LicensePlateModel(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      imagePath: imagePath ?? this.imagePath,
      recognizedAt: recognizedAt ?? this.recognizedAt,
      detectedAt: detectedAt ?? this.detectedAt,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      ocrProvider: ocrProvider ?? this.ocrProvider,
      ocrMetadata: ocrMetadata ?? this.ocrMetadata,
      isValidFormat: isValidFormat ?? this.isValidFormat,
    );
  }

  bool get hasPlateNumber => plateNumber != null && plateNumber!.isNotEmpty;
  bool get isHighConfidence => confidence != null && confidence! > 0.8;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'imagePath': imagePath,
      'recognizedAt': recognizedAt?.millisecondsSinceEpoch,
      'detectedAt': detectedAt?.millisecondsSinceEpoch,
      'confidence': confidence,
      'rawText': rawText,
      'ocrProvider': ocrProvider,
      'ocrMetadata': ocrMetadata,
      'isValidFormat': isValidFormat,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'image_path': imagePath,
      'recognized_at': recognizedAt?.millisecondsSinceEpoch,
      'confidence': confidence,
      'raw_text': rawText,
      'ocr_provider': ocrProvider ?? 'google_mlkit',
      'is_valid_format': isValidFormat ? 1 : 0,
    };
  }

  static LicensePlateModel fromMap(Map<String, dynamic> map) {
    return LicensePlateModel(
      id: map['id'] ?? '',
      plateNumber: map['plateNumber'],
      imagePath: map['imagePath'],
      recognizedAt: map['recognizedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['recognizedAt'])
          : null,
      detectedAt: map['detectedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['detectedAt'])
          : null,
      confidence: map['confidence']?.toDouble(),
      rawText: map['rawText'],
      ocrProvider: map['ocrProvider'],
      ocrMetadata: map['ocrMetadata'],
      isValidFormat: map['isValidFormat'] ?? false,
    );
  }

  static LicensePlateModel fromDatabaseMap(Map<String, dynamic> map) {
    return LicensePlateModel(
      id: map['id']?.toString() ?? '',
      plateNumber: map['plate_number'],
      imagePath: map['image_path'],
      recognizedAt: map['recognized_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['recognized_at'])
          : null,
      confidence: map['confidence']?.toDouble(),
      rawText: map['raw_text'],
      ocrProvider: map['ocr_provider'] ?? 'google_mlkit',
      isValidFormat: (map['is_valid_format'] ?? 0) == 1,
    );
  }

  @override
  String toString() {
    return 'LicensePlateModel(plate: $plateNumber, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LicensePlateModel && other.plateNumber == plateNumber;
  }

  @override
  int get hashCode => plateNumber.hashCode;
}