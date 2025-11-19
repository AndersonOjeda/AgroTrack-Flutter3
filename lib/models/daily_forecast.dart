class DailyForecast {
  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final String description;
  final String icon;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.description,
    required this.icon,
    required this.weatherCode,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.parse(json['date'] as String),
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      weatherCode: json['weatherCode'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'description': description,
      'icon': icon,
      'weatherCode': weatherCode,
    };
  }
}
