// lib/app/services/event_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/event_item.dart';
import '../controllers/login_controller.dart';
import '../config/app_config.dart';

class EventService extends GetxService {
  final LoginController _loginController = Get.find<LoginController>();

  Future<String?> _getAccessToken() async {
    return _loginController.user.safeAccessToken;
  }

  Map<String, String> _createHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET /api/v1/events - 내 이벤트 목록 조회
  Future<List<EventItem>> getEvents() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('액세스 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/events');

    try {
      final response = await http.get(
        requestUri,
        headers: _createHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData.map((data) => EventItem.fromJson(data as Map<String, dynamic>)).toList();
      } else if (response.statusCode == 401) {
        // TODO: 토큰 만료 시 자동 갱신 로직 또는 로그아웃 처리
        _loginController.logout(); // 예시: 인증 실패 시 로그아웃
        throw Exception('인증 실패: ${response.body}');
      } else {
        throw Exception('이벤트 목록 조회 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EventService] getEvents Error: $e');
      }
      rethrow; // 에러를 다시 던져서 호출한 쪽에서 처리할 수 있도록 함
    }
  }

  // POST /api/v1/events - 새 이벤트 생성
  Future<EventItem> createEvent(EventItem event) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('액세스 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/events');
    final requestBody = event.toJsonForCreate();

    try {
      final response = await http.post(
        requestUri,
        headers: _createHeaders(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return EventItem.fromJson(responseData as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청 형식: ${response.body}');
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else {
        throw Exception('이벤트 생성 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EventService] createEvent Error: $e');
      }
      rethrow;
    }
  }

  // PUT /api/v1/events - 이벤트 수정
  Future<EventItem> updateEvent(EventItem event) async {
    if (event.backendEventId == null) {
      throw Exception('수정할 이벤트의 ID가 없습니다.');
    }
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('액세스 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/events'); // API 명세상 PUT도 /api/v1/events
    final requestBody = event.toJsonForUpdate(); // backendEventId가 eventId 키로 포함됨

    try {
      final response = await http.put(
        requestUri,
        headers: _createHeaders(token),
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return EventItem.fromJson(responseData as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청 형식: ${response.body}');
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else if (response.statusCode == 403) {
        throw Exception('권한 없음 (자신의 이벤트가 아님): ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception('수정할 이벤트를 찾을 수 없음: ${response.body}');
      } else {
        throw Exception('이벤트 수정 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EventService] updateEvent Error: $e');
      }
      rethrow;
    }
  }

  // DELETE /api/v1/events - 이벤트 삭제
  Future<void> deleteEvent(String backendEventId) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('액세스 토큰이 없습니다. 로그인이 필요합니다.');
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    // API 명세에 따르면 DELETE 요청 시 본문에 eventId를 포함해야 합니다.
    // http.delete는 기본적으로 body를 지원하지만, 서버 구현에 따라 query parameter를 사용할 수도 있습니다.
    // 여기서는 명세대로 body에 eventId를 포함하여 전송합니다.
    final Uri requestUri = Uri.parse('$baseUrl/api/v1/events');
    final requestBody = {'eventId': backendEventId};

    try {
      // http.delete 메서드에 body를 직접 전달할 수 없으므로, http.Request를 사용합니다.
      final request = http.Request('DELETE', requestUri);
      request.headers.addAll(_createHeaders(token));
      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 204) {
        // 성공적으로 삭제됨 (No Content)
        return;
      } else if (response.statusCode == 400) {
        throw Exception('잘못된 요청 형식: ${response.body}');
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else if (response.statusCode == 403) {
        throw Exception('권한 없음 (자신의 이벤트가 아님): ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception('삭제할 이벤트를 찾을 수 없음: ${response.body}');
      } else {
        throw Exception('이벤트 삭제 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EventService] deleteEvent Error: $e');
      }
      rethrow;
    }
  }
}