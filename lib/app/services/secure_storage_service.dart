// lib/app/services/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 저장 시 사용할 키 정의
  static const String keyRefreshToken = 'refreshToken';
  static const String keyAccessToken = 'accessToken';
  static const String keyUserId = 'userId';
  static const String keyPlatform = 'platform';
  static const String keyNickname = 'nickname';
  static const String keyIsNew = 'isNew';
  static const String keyUserCreatedAt = 'userCreatedAt'; // createdAt 키 추가

  // 사용자 인증 관련 정보 저장
  Future<void> saveUserAuthData({
    required String refreshToken,
    String? accessToken,
    required String userId,
    required String platform,
    String? nickname,
    bool? isNew,
    String? userCreatedAt, // DateTime을 String (ISO8601)으로 받아 저장
  }) async {
    await _storage.write(key: keyRefreshToken, value: refreshToken);
    if (accessToken != null) {
      await _storage.write(key: keyAccessToken, value: accessToken);
    }
    await _storage.write(key: keyUserId, value: userId);
    await _storage.write(key: keyPlatform, value: platform);
    if (nickname != null) {
      await _storage.write(key: keyNickname, value: nickname);
    }
    if (isNew != null) {
      await _storage.write(
        key: keyIsNew,
        value: isNew.toString(),
      );
    }
    if (userCreatedAt != null) { // createdAt 저장 로직 추가
      await _storage.write(key: keyUserCreatedAt, value: userCreatedAt);
    }
  }

  // 저장된 사용자 인증 관련 정보 조회
  Future<Map<String, String?>?> getUserAuthData() async {
    final refreshToken = await _storage.read(key: keyRefreshToken);
    if (refreshToken == null) {
      return null;
    }
    final accessToken = await _storage.read(key: keyAccessToken);
    final userId = await _storage.read(key: keyUserId);
    final platform = await _storage.read(key: keyPlatform);
    final nickname = await _storage.read(key: keyNickname);
    final isNewString = await _storage.read(key: keyIsNew);
    final userCreatedAtString = await _storage.read(key: keyUserCreatedAt); // createdAt 로드 로직 추가

    return {
      keyRefreshToken: refreshToken,
      keyAccessToken: accessToken,
      keyUserId: userId,
      keyPlatform: platform,
      keyNickname: nickname,
      keyIsNew: isNewString,
      keyUserCreatedAt: userCreatedAtString,
    };
  }

  // 저장된 모든 사용자 인증 관련 정보 삭제 (로그아웃 시)
  Future<void> clearUserAuthData() async {
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keyAccessToken);
    await _storage.delete(key: keyUserId);
    await _storage.delete(key: keyPlatform);
    await _storage.delete(key: keyNickname);
    await _storage.delete(key: keyIsNew);
    await _storage.delete(key: keyUserCreatedAt); // createdAt 삭제 로직 추가
    print('[SecureStorageService] Secure storage cleared for user auth data.');
  }

  Future<String?> getRefreshToken() => _storage.read(key: keyRefreshToken);
  Future<String?> getAccessToken() => _storage.read(key: keyAccessToken);
// keyUserCreatedAt에 대한 getter는 필요시 추가 가능
// Future<String?> getUserCreatedAt() => _storage.read(key: keyUserCreatedAt);
}