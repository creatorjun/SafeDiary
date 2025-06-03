// lib/app/services/user_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
// import 'package:get/get.dart'; // GetxService를 사용하지 않는다면 제거 가능
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
// User 모델 등 다른 모델이 필요하면 임포트

class UserService { // GetxService를 사용하지 않고 일반 클래스로 만들어도 무방합니다.
  // Get.find()로 주입받지 않고 직접 생성자 주입 등을 사용할 수 있습니다.

  /// 사용자 닉네임을 서버에 업데이트합니다.
  /// 성공 시 true, 실패 시 false 또는 예외 발생.
  Future<bool> updateNickname(String newNickname, String accessToken) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }
    if (newNickname.trim().isEmpty) {
      throw Exception('닉네임은 비워둘 수 없습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me');
    if (kDebugMode) {
      print('[UserService] updateNickname to: $newNickname');
    }

    try {
      final response = await http.patch(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({'nickname': newNickname}),
      );

      if (kDebugMode) {
        print('[UserService] updateNickname response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '닉네임 변경 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] updateNickname Error: $e');
      }
      rethrow;
    }
  }

  /// 앱 접근 비밀번호를 서버와 검증합니다.
  /// 성공(일치) 시 true, 실패(불일치 등) 시 false 또는 예외 발생.
  Future<bool> verifyAppPassword(String appPassword, String accessToken) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/verify-app-password');
    if (kDebugMode) {
      print('[UserService] verifyAppPassword');
    }
    try {
      final response = await http.post(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({'appPassword': appPassword}),
      );

      if (kDebugMode) {
        print('[UserService] verifyAppPassword response status: ${response.statusCode}');
        print('[UserService] verifyAppPassword response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData['isVerified'] as bool? ?? false;
      } else if (response.statusCode == 401) { // 비밀번호 불일치
        return false; // 또는 특정 예외를 던져 컨트롤러에서 구분하도록 할 수 있습니다.
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '앱 비밀번호 검증 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] verifyAppPassword Error: $e');
      }
      rethrow;
    }
  }

  /// 새 앱 접근 비밀번호를 설정하거나 기존 비밀번호를 변경합니다.
  /// 성공 시 true, 실패 시 false 또는 예외 발생.
  Future<bool> setOrUpdateAppPassword({
    String? currentAppPassword, // 변경 시에만 필요
    required String newAppPassword,
    required String accessToken,
  }) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me'); // PATCH /api/v1/users/me
    Map<String, String?> requestBody = {'newAppPassword': newAppPassword};
    if (currentAppPassword != null && currentAppPassword.isNotEmpty) {
      requestBody['currentAppPassword'] = currentAppPassword;
    }

    if (kDebugMode) {
      print('[UserService] setOrUpdateAppPassword requestBody: $requestBody');
    }

    try {
      final response = await http.patch(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('[UserService] setOrUpdateAppPassword response status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401 && currentAppPassword != null) { // 현재 비밀번호 불일치
        throw Exception('현재 앱 비밀번호가 일치하지 않습니다.');
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '앱 비밀번호 설정/변경 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] setOrUpdateAppPassword Error: $e');
      }
      rethrow;
    }
  }

  /// 앱 접근 비밀번호를 서버에서 해제합니다.
  /// 성공 시 true, 실패 시 false 또는 예외 발생.
  Future<bool> removeAppPassword(String currentAppPassword, String accessToken) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }
    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/app-password'); // DELETE /api/v1/users/me/app-password

    if (kDebugMode) {
      print('[UserService] removeAppPassword');
    }

    try {
      final request = http.Request('DELETE', requestUri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });
      request.body = json.encode({'currentAppPassword': currentAppPassword});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('[UserService] removeAppPassword response status: ${response.statusCode}');
      }

      if (response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) { // 현재 비밀번호 불일치
        throw Exception('현재 앱 비밀번호가 일치하지 않아 해제할 수 없습니다.');
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '앱 비밀번호 해제 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] removeAppPassword Error: $e');
      }
      rethrow;
    }
  }

  /// 파트너 관계를 해제하고 관련 데이터를 서버에서 삭제 요청합니다.
  /// 성공 시 true, 실패 시 false 또는 예외 발생.
  Future<bool> unfriendPartner(String accessToken) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/partner'); // DELETE /api/v1/users/me/partner
    if (kDebugMode) {
      print('[UserService] unfriendPartner');
    }
    try {
      final response = await http.delete(
        requestUri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (kDebugMode) {
        print('[UserService] unfriendPartner response status: ${response.statusCode}');
      }
      if (response.statusCode == 204) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '파트너 관계 해제 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] unfriendPartner Error: $e');
      }
      rethrow;
    }
  }

  /// 회원 탈퇴를 위해 서버에 사용자 계정 삭제를 요청합니다.
  /// 성공 시 true, 실패 시 false 또는 예외 발생.
  Future<bool> deleteUserAccount(String accessToken) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me'); // DELETE /api/v1/users/me
    if (kDebugMode) {
      print('[UserService] deleteUserAccount');
    }
    try {
      final response = await http.delete(
        requestUri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        print('[UserService] deleteUserAccount response status: ${response.statusCode}');
      }

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '회원 탈퇴 실패 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] deleteUserAccount Error: $e');
      }
      rethrow;
    }
  }
}