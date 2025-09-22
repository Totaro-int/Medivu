class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? district;
  final DateTime timestamp;
  final double? accuracy;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.district,
    required this.timestamp,
    this.accuracy,
  });

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? district,
    DateTime? timestamp,
    double? accuracy,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'district': district,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }

  static LocationModel fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      city: map['city'],
      district: map['district'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      accuracy: map['accuracy']?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}