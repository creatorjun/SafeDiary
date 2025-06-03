import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';
import '../config/app_config.dart';

class WeatherService {
  Future<WeeklyForecastResponseDto> getWeeklyForecastByCityName(
      String cityName, [String? date]) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    String endpoint = '$baseUrl/api/v1/weather/weekly/by-city-name/$cityName';
    if (date != null && date.isNotEmpty) {
      endpoint += '?date=$date';
    }

    final Uri requestUri = Uri.parse(endpoint);

    if (kDebugMode) {
      print('[WeatherService] Requesting weather forecast: $requestUri');
    }

    try {
      final response = await http.get(requestUri);

      if (kDebugMode) {
        print(
            '[WeatherService] Response status: ${response.statusCode}');
        // print('[WeatherService] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        return WeeklyForecastResponseDto.fromJson(responseData);
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청입니다 (예: 유효하지 않은 날짜 형식).');
      } else if (response.statusCode == 404) {
        throw Exception('해당 도시의 예보를 찾을 수 없습니다.');
      } else {
        throw Exception('주간 예보 조회 실패 (코드: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WeatherService] getWeeklyForecastByCityName Error: $e');
      }
      rethrow;
    }
  }
}