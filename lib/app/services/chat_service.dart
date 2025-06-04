import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/chat_models.dart';
import '../controllers/login_controller.dart';
import '../config/app_config.dart';

class ChatService extends GetxService {
  final LoginController _loginController = Get.find<LoginController>();

  Future<String?> _getAccessToken() async {
    // User 객체가 null이 아니고, safeAccessToken이 null이 아닌지 확인
    if (_loginController.user.safeAccessToken == null) {
      // 토큰이 없는 경우, 예를 들어 로그아웃 상태이거나 토큰 갱신 실패 시
      // 필요하다면 여기서 로그인 화면으로 리다이렉트하거나 예외를 던질 수 있습니다.
      // 지금은 null을 반환하여 호출하는 쪽에서 처리하도록 합니다.
      if (kDebugMode) {
        print('[ChatService] Access token is null. User might be logged out.');
      }
      // 경우에 따라 강제 로그아웃 또는 로그인 페이지 이동 로직 추가 가능
      // _loginController.logout();
      // throw Exception('Access Token is null. Please login again.');
      return null;
    }
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

  // GET /api/v1/chat/with/{otherUserUid}/messages
  Future<PaginatedChatMessagesResponse> getChatMessages({
    required String otherUserUid,
    int? beforeTimestamp,
    int size = 20,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Map<String, String> queryParams = {'size': size.toString()};
    if (beforeTimestamp != null) {
      queryParams['before'] = beforeTimestamp.toString();
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/chat/with/$otherUserUid/messages')
        .replace(queryParameters: queryParams);

    if (kDebugMode) {
      print('[ChatService] Requesting chat messages: $requestUri');
    }

    try {
      final response = await http.get(
        requestUri,
        headers: _createHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        return PaginatedChatMessagesResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else {
        throw Exception(
            '채팅 메시지 조회 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatService] getChatMessages Error: $e');
      }
      rethrow;
    }
  }

  // GET /api/v1/chat/with/{otherUserUid}/messages/search
  Future<PaginatedChatMessagesResponse> searchChatMessages({
    required String otherUserUid,
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Map<String, String> queryParams = {
      'keyword': keyword,
      'page': page.toString(),
      'size': size.toString(),
      // 'sort': 'createdAt,desc', // API 명세에 따라 필요시 추가
    };

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/chat/with/$otherUserUid/messages/search')
        .replace(queryParameters: queryParams);

    if (kDebugMode) {
      print('[ChatService] Searching chat messages: $requestUri');
    }

    try {
      final response = await http.get(
        requestUri,
        headers: _createHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        return PaginatedChatMessagesResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else {
        throw Exception(
            '채팅 메시지 검색 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatService] searchChatMessages Error: $e');
      }
      rethrow;
    }
  }

  // DELETE /api/v1/chat/messages/{messageId}
  Future<void> deleteChatMessage(String messageId) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/chat/messages/$messageId');

    if (kDebugMode) {
      print('[ChatService] Deleting chat message: $requestUri');
    }

    try {
      final response = await http.delete(
        requestUri,
        headers: _createHeaders(token),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 성공 (204 No Content 또는 API 설계에 따라 200 OK)
        return;
      } else if (response.statusCode == 401) {
        _loginController.logout();
        throw Exception('인증 실패: ${response.body}');
      } else {
        throw Exception(
            '채팅 메시지 삭제 실패 (코드: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatService] deleteChatMessage Error: $e');
      }
      rethrow;
    }
  }

// STOMP 메시지 전송을 위한 메서드 (추후 ChatController에서 구현)
// 이 서비스에서는 직접 STOMP 클라이언트를 관리하지 않고,
// ChatController에서 StompService(가칭) 또는 직접 StompClient를 사용하여 메시지를 전송하고,
// 여기서는 해당 메시지 객체를 생성하거나 API를 통해 보내는 로직만 담당할 수 있습니다.
// 지금은 REST API 기반이므로, 만약 채팅 메시지 전송도 HTTP POST를 사용한다면 여기에 추가합니다.
// (현재 Swagger에는 메시지 전송 API가 보이지 않으므로, STOMP/WebSocket을 가정)

}