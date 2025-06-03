import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/luck_models.dart'; // 생성한 운세 모델 임포트
import '../config/app_config.dart';

class LuckService {
  Future<ZodiacLuckData> getTodaysLuck(String zodiacName) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    // URL 인코딩을 고려하여 zodiacName을 처리할 수 있지만,
    // 일반적으로 한글 띠 이름은 경로 변수로 문제없이 사용될 수 있습니다.
    // 만약 문제가 발생하면 Uri.encodeComponent(zodiacName) 사용을 고려합니다.
    final String endpoint = '$baseUrl/api/v1/luck/today/$zodiacName';
    final Uri requestUri = Uri.parse(endpoint);

    if (kDebugMode) {
      print('[LuckService] Requesting today\'s luck: $requestUri');
    }

    try {
      final response = await http.get(requestUri);

      if (kDebugMode) {
        print('[LuckService] Response status: ${response.statusCode}');
        // print('[LuckService] Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        return ZodiacLuckData.fromJson(responseData);
      } else if (response.statusCode == 400) {
        // 400 에러의 경우, API 명세에 따라 "잘못된 띠 이름"일 수 있음
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '잘못된 띠 이름입니다.';
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        // 404 에러의 경우, "해당 띠 또는 해당 날짜의 운세 정보를 찾을 수 없거나 아직 준비되지 않음"
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '운세 정보를 찾을 수 없거나 아직 준비되지 않았습니다.';
        throw Exception(errorMessage);
      }
      else {
        throw Exception('오늘의 운세 조회 실패 (코드: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LuckService] getTodaysLuck Error: $e');
      }
      // 여기서 에러를 좀 더 사용자 친화적으로 만들거나, 특정 예외 타입으로 변환할 수 있습니다.
      // 예를 들어, 네트워크 연결 문제 등
      rethrow;
    }
  }
}