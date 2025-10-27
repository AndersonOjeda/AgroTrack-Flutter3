class WeatherLocation {
  final String id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime createdAt;

  const WeatherLocation({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    required this.createdAt,
  });

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WeatherLocation copyWith({
    String? id,
    String? name,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WeatherLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WeatherLocation(id: $id, name: $name, country: $country, lat: $latitude, lng: $longitude, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherLocation &&
        other.id == id &&
        other.name == name &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, country, latitude, longitude, isDefault);
  }
}