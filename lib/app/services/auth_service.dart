// lib/app/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';

class AuthService extends GetxService {
  final SecureStorageService _secureStorageService = Get.find<SecureStorageService>();

  Future<User?> signInWithSocialUser(User socialUserInfo) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/auth/social/login');
    final requestBody = {
      'id': socialUserInfo.id, // 소셜 ID는 'id'로 전송
      'nickname': socialUserInfo.nickname,
      'platform': socialUserInfo.platform.name,
      'socialAccessToken': socialUserInfo.socialAccessToken,
    };

    if (kDebugMode) {
      print('[AuthService] signInWithSocialUser requestBody: $requestBody');
    }

    try {
      final response = await http.post(
        requestUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (kDebugMode) {
        print('[AuthService] signInWithSocialUser response status: ${response.statusCode}');
        print('[AuthService] signInWithSocialUser response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final String? newAccessToken = responseData['accessToken'] as String?;
        final String? newRefreshToken = responseData['refreshToken'] as String?;

        final String serverUserId = responseData['uid'] as String? ?? "";
        final String serverNickname = responseData['nickname'] as String? ?? socialUserInfo.nickname ?? "";
        final LoginPlatform serverPlatform = LoginPlatform.values.firstWhere(
                (e) => e.name == (responseData['loginProvider'] as String? ?? responseData['platform'] as String?),
            orElse: () => socialUserInfo.platform);
        final bool isNewFromServer = responseData['isNew'] as bool? ?? false;
        final bool isAppPasswordSetFromServer = responseData['appPasswordSet'] as bool? ?? false;
        final String? partnerUidServer = responseData['partnerUid'] as String?;
        final String? createdAtString = responseData['createdAt'] as String?;
        DateTime? createdAtDate;

        if (createdAtString != null && createdAtString.isNotEmpty) {
          try {
            createdAtDate = DateTime.parse(createdAtString);
          } catch (e) {
            if (kDebugMode) {
              print("[AuthService] Error parsing createdAt from server: $e");
            }
          }
        }

        if (serverUserId.isEmpty) {
          throw Exception('서버로부터 사용자 ID(uid)를 받지 못했습니다.');
        }
        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw Exception('서버로부터 액세스 토큰을 받지 못했습니다.');
        }
        if (newRefreshToken == null || newRefreshToken.isEmpty) {
          throw Exception('서버로부터 리프레시 토큰을 받지 못했습니다.');
        }

        await _secureStorageService.saveRefreshToken(
          refreshToken: newRefreshToken,
        );

        return User(
          id: serverUserId,
          nickname: serverNickname,
          platform: serverPlatform,
          socialAccessToken: socialUserInfo.socialAccessToken,
          safeAccessToken: newAccessToken,
          safeRefreshToken: newRefreshToken,
          isNew: isNewFromServer,
          isAppPasswordSet: isAppPasswordSetFromServer,
          partnerUid: partnerUidServer,
          createdAt: createdAtDate,
        );
      } else {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '서버 통신 오류 (코드: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] signInWithSocialUser Error: $e');
      }
      rethrow;
    }
  }

  Future<User?> attemptAutoLogin() async {
    final String? refreshToken = await _secureStorageService.getRefreshToken();
    if (refreshToken == null) {
      if (kDebugMode) print('[AuthService] No refresh token found for auto-login.');
      return null;
    }

    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      throw Exception('API URL이 설정되지 않았습니다.');
    }

    final Uri refreshUri = Uri.parse('$baseUrl/api/v1/auth/refresh');
    if (kDebugMode) {
      print('[AuthService] attemptAutoLogin with RT: $refreshToken');
    }

    try {
      final refreshResponse = await http.post(
        refreshUri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $refreshToken'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (kDebugMode) {
        print('[AuthService] attemptAutoLogin response status: ${refreshResponse.statusCode}');
        print('[AuthService] attemptAutoLogin response body: ${refreshResponse.body}');
      }

      if (refreshResponse.statusCode == 200) {
        final responseData = json.decode(utf8.decode(refreshResponse.bodyBytes));
        final String? newAccessToken = responseData['accessToken'] as String?;
        final String? newRefreshTokenFromResponse = responseData['refreshToken'] as String?;

        // '/auth/refresh' 엔드포인트에서도 사용자 ID를 'uid'로 파싱합니다.
        final String refreshedUserId = responseData['uid'] as String? ?? ""; // <<< 여기를 'uid'로 수정했습니다.
        final String refreshedNickname = responseData['nickname'] as String? ?? "";
        final LoginPlatform refreshedPlatform = LoginPlatform.values.firstWhere(
                (e) => e.name == (responseData['loginProvider'] as String? ?? responseData['platform'] as String?),
            orElse: () => LoginPlatform.none);
        final bool refreshedIsNew = responseData['isNew'] as bool? ?? false;
        final bool refreshedIsAppPasswordSet = responseData['appPasswordSet'] as bool? ?? false;
        final String? refreshedPartnerUid = responseData['partnerUid'] as String?;
        final String? createdAtStringFromServer = responseData['createdAt'] as String?;
        DateTime? refreshedCreatedAt;

        if (createdAtStringFromServer != null && createdAtStringFromServer.isNotEmpty) {
          try {
            refreshedCreatedAt = DateTime.parse(createdAtStringFromServer);
          } catch (e) {
            if (kDebugMode) {
              print("[AuthService] Error parsing createdAt during auto-login: $e");
            }
          }
        }

        if (refreshedUserId.isEmpty) {
          throw Exception('자동 로그인 시 서버로부터 사용자 ID(uid)를 받지 못했습니다.');
        }
        if (newAccessToken == null || newAccessToken.isEmpty) {
          throw Exception('자동 로그인 시 서버로부터 액세스 토큰을 받지 못했습니다.');
        }

        final String finalRefreshToken = newRefreshTokenFromResponse ?? refreshToken;
        await _secureStorageService.saveRefreshToken(
          refreshToken: finalRefreshToken,
        );

        return User(
          id: refreshedUserId,
          nickname: refreshedNickname,
          platform: refreshedPlatform,
          safeAccessToken: newAccessToken,
          safeRefreshToken: finalRefreshToken,
          isNew: refreshedIsNew,
          isAppPasswordSet: refreshedIsAppPasswordSet,
          partnerUid: refreshedPartnerUid,
          createdAt: refreshedCreatedAt,
        );
      } else {
        await _secureStorageService.clearRefreshToken();
        final errorBody = json.decode(utf8.decode(refreshResponse.bodyBytes));
        final errorMessage = errorBody['message'] as String? ?? '자동 로그인 실패 (토큰 갱신 실패 코드: ${refreshResponse.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] attemptAutoLogin Error: $e');
      }
      rethrow;
    }
  }

  Future<void> clearTokensOnLogout() async {
    await _secureStorageService.clearRefreshToken();
    if (kDebugMode) {
      print('[AuthService] Tokens cleared on logout.');
    }
  }
}