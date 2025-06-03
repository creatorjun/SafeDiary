// lib/app/services/secure_storage_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 저장 시 사용할 키 정의
  static const String keyRefreshToken = 'refreshToken';

  // 리프레시 토큰 저장
  Future<void> saveRefreshToken({
    required String refreshToken,
  }) async {
    await _storage.write(key: keyRefreshToken, value: refreshToken);
  }

  // 저장된 리프레시 토큰 조회
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: keyRefreshToken);
  }

  // 저장된 리프레시 토큰 삭제 (로그아웃 또는 토큰 만료 시)
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: keyRefreshToken);
    if(kDebugMode) print('[SecureStorageService] Refresh token cleared from secure storage.');
  }

  // 모든 사용자 인증 관련 정보 삭제 (앱 초기화 또는 전체 데이터 삭제 필요시)
  // 이 함수는 여전히 모든 정의된 키를 삭제하려고 시도할 수 있으나,
  // 주 사용은 clearRefreshToken으로 대체될 수 있습니다.
  Future<void> clearAllUserAuthData() async {
    await _storage.delete(key: keyRefreshToken);
    if(kDebugMode) print('[SecureStorageService] All user auth related data attempt to clear.');
  }
}