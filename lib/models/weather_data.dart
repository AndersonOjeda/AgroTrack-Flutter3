class WeatherData {
  final String locationId;
  final String locationName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String description;
  final String icon;
  final double windSpeed;
  final int pressure;
  final double? rainProbability;
  final DateTime timestamp;
  final List<WeatherForecast> forecast;

  const WeatherData({
    required this.locationId,
    required this.locationName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.pressure,
    this.rainProbability,
    required this.timestamp,
    this.forecast = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'] as int,
      description: json['description'] as String,
      icon: json['icon'] as String,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      pressure: json['pressure'] as int,
      rainProbability: json['rain_probability'] != null 
          ? (json['rain_probability'] as num).toDouble() 
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      forecast: (json['forecast'] as List<dynamic>?)
          ?.map((item) => WeatherForecast.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'location_name': locationName,
      'temperature': temperature,
      'feels_like': feelsLike,
      'humidity': humidity,
      'description': description,
      'icon': icon,
      'wind_speed': windSpeed,
      'pressure': pressure,
      'rain_probability': rainProbability,
      'timestamp': timestamp.toIso8601String(),
      'forecast': forecast.map((item) => item.toJson()).toList(),
    };
  }

  String get temperatureString => '${temperature.round()}°';
  String get humidityString => '$humidity%';
  String get windSpeedString => '${windSpeed.toStringAsFixed(1)} km/h';
  String get pressureString => '$pressure hPa';
  String get rainProbabilityString => rainProbability != null 
      ? '${(rainProbability! * 100).round()}%' 
      : '0%';
}

class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String description;
  final String icon;
  final double rainProbability;

  const WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.description,
    required this.icon,
    required this.rainProbability,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.parse(json['date'] as String),
      maxTemp: (json['max_temp'] as num).toDouble(),
      minTemp: (json['min_temp'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      rainProbability: (json['rain_probability'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'max_temp': maxTemp,
      'min_temp': minTemp,
      'description': description,
      'icon': icon,
      'rain_probability': rainProbability,
    };
  }

  String get maxTempString => '${maxTemp.round()}°';
  String get minTempString => '${minTemp.round()}°';
  String get rainProbabilityString => '${(rainProbability * 100).round()}%';
}