class WeeklyForecastResponseDto {
  final String regionCode;
  final String? regionName;
  final List<WeatherForecastResponseDto> forecasts;

  WeeklyForecastResponseDto({
    required this.regionCode,
    this.regionName,
    required this.forecasts,
  });

  factory WeeklyForecastResponseDto.fromJson(Map<String, dynamic> json) {
    var list = json['forecasts'] as List? ?? [];
    List<WeatherForecastResponseDto> forecastsList =
    list.map((i) => WeatherForecastResponseDto.fromJson(i)).toList();

    return WeeklyForecastResponseDto(
      regionCode: json['regionCode'] as String? ?? '',
      regionName: json['regionName'] as String?,
      forecasts: forecastsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regionCode': regionCode,
      'regionName': regionName,
      'forecasts': forecasts.map((v) => v.toJson()).toList(),
    };
  }
}

class WeatherForecastResponseDto {
  final String date;
  final String? regionCode;
  final String? regionName;
  final int? minTemp;
  final int? maxTemp;
  final String? weatherAm;
  final String? weatherPm;
  final int? rainProbAm;
  final int? rainProbPm;

  WeatherForecastResponseDto({
    required this.date,
    this.regionCode,
    this.regionName,
    this.minTemp,
    this.maxTemp,
    this.weatherAm,
    this.weatherPm,
    this.rainProbAm,
    this.rainProbPm,
  });

  factory WeatherForecastResponseDto.fromJson(Map<String, dynamic> json) {
    return WeatherForecastResponseDto(
      date: json['date'] as String? ?? '',
      regionCode: json['regionCode'] as String?,
      regionName: json['regionName'] as String?,
      minTemp: json['minTemp'] as int?,
      maxTemp: json['maxTemp'] as int?,
      weatherAm: json['weatherAm'] as String?,
      weatherPm: json['weatherPm'] as String?,
      rainProbAm: json['rainProbAm'] as int?,
      rainProbPm: json['rainProbPm'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'regionCode': regionCode,
      'regionName': regionName,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'weatherAm': weatherAm,
      'weatherPm': weatherPm,
      'rainProbAm': rainProbAm,
      'rainProbPm': rainProbPm,
    };
  }
}