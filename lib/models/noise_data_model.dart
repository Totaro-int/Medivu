class NoiseDataModel {
  final double currentDecibel;
  final double? minDecibel;
  final double? maxDecibel;
  final double? avgDecibel;
  final DateTime startTime;
  final DateTime? endTime;
  final int measurementCount;
  final List<double> readings;

  const NoiseDataModel({
    required this.currentDecibel,
    this.minDecibel,
    this.maxDecibel,
    this.avgDecibel,
    required this.startTime,
    this.endTime,
    required this.measurementCount,
    required this.readings,
  });

  NoiseDataModel copyWith({
    double? currentDecibel,
    double? minDecibel,
    double? maxDecibel,
    double? avgDecibel,
    DateTime? startTime,
    DateTime? endTime,
    int? measurementCount,
    List<double>? readings,
  }) {
    return NoiseDataModel(
      currentDecibel: currentDecibel ?? this.currentDecibel,
      minDecibel: minDecibel ?? this.minDecibel,
      maxDecibel: maxDecibel ?? this.maxDecibel,
      avgDecibel: avgDecibel ?? this.avgDecibel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      measurementCount: measurementCount ?? this.measurementCount,
      readings: readings ?? this.readings,
    );
  }

  Duration? get measurementDuration {
    return endTime?.difference(startTime);
  }

  bool get isComplete => endTime != null;

  Map<String, dynamic> toMap() {
    return {
      'currentDecibel': currentDecibel,
      'minDecibel': minDecibel,
      'maxDecibel': maxDecibel,
      'avgDecibel': avgDecibel,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'measurementCount': measurementCount,
      'readings': readings,
    };
  }

  static NoiseDataModel fromMap(Map<String, dynamic> map) {
    return NoiseDataModel(
      currentDecibel: map['currentDecibel']?.toDouble() ?? 0.0,
      minDecibel: map['minDecibel']?.toDouble(),
      maxDecibel: map['maxDecibel']?.toDouble(),
      avgDecibel: map['avgDecibel']?.toDouble(),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      measurementCount: map['measurementCount'] ?? 0,
      readings: List<double>.from(map['readings'] ?? []),
    );
  }

  @override
  String toString() {
    return 'NoiseDataModel(current: $currentDecibel dB, count: $measurementCount)';
  }
}