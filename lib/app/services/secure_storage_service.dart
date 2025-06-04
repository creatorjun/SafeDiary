// lib/app/services/secure_storage_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 저장 시 사용할 키 정의
  static const String keyRefreshToken = 'refreshToken';
  static const String keySelectedCity = 'selectedCity';
  static const String keySelectedZodiac = 'selectedZodiac';
  static const String keyFailedAttemptCount = 'failedAttemptCount'; // 실패 횟수 키

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

  // 저장된 리프레시 토큰 삭제
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: keyRefreshToken);
    if (kDebugMode) print('[SecureStorageService] Refresh token cleared.');
  }

  // 선택된 도시 이름 저장
  Future<void> saveSelectedCity(String cityName) async {
    await _storage.write(key: keySelectedCity, value: cityName);
    if (kDebugMode) print('[SecureStorageService] Saved selected city: $cityName');
  }

  // 저장된 도시 이름 조회
  Future<String?> getSelectedCity() async {
    final String? city = await _storage.read(key: keySelectedCity);
    if (kDebugMode) print('[SecureStorageService] Retrieved selected city: $city');
    return city;
  }

  // 선택된 도시 이름 삭제
  Future<void> clearSelectedCity() async {
    await _storage.delete(key: keySelectedCity);
    if (kDebugMode) print('[SecureStorageService] Selected city cleared.');
  }

  // 선택된 띠 이름 저장
  Future<void> saveSelectedZodiac(String zodiacName) async {
    await _storage.write(key: keySelectedZodiac, value: zodiacName);
    if (kDebugMode) print('[SecureStorageService] Saved selected zodiac: $zodiacName');
  }

  // 저장된 띠 이름 조회
  Future<String?> getSelectedZodiac() async {
    final String? zodiac = await _storage.read(key: keySelectedZodiac);
    if (kDebugMode) print('[SecureStorageService] Retrieved selected zodiac: $zodiac');
    return zodiac;
  }

  // 선택된 띠 이름 삭제 (필요시 사용)
  Future<void> clearSelectedZodiac() async {
    await _storage.delete(key: keySelectedZodiac);
    if (kDebugMode) print('[SecureStorageService] Selected zodiac cleared.');
  }

  // 실패 횟수 저장
  Future<void> saveFailedAttemptCount(int count) async {
    await _storage.write(key: keyFailedAttemptCount, value: count.toString());
    if (kDebugMode) print('[SecureStorageService] Saved failed attempt count: $count');
  }

  // 저장된 실패 횟수 조회
  Future<int> getFailedAttemptCount() async {
    final String? countStr = await _storage.read(key: keyFailedAttemptCount);
    final int count = countStr != null ? (int.tryParse(countStr) ?? 0) : 0;
    if (kDebugMode) print('[SecureStorageService] Retrieved failed attempt count: $count');
    return count;
  }

  // 저장된 실패 횟수 초기화 (0으로 설정)
  Future<void> clearFailedAttemptCount() async {
    await _storage.write(key: keyFailedAttemptCount, value: '0');
    if (kDebugMode) print('[SecureStorageService] Failed attempt count cleared to 0.');
  }

  // 모든 사용자 관련 데이터 삭제 (토큰, 도시, 띠 정보, 실패 횟수)
  Future<void> clearAllUserData() async {
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keySelectedCity);
    await _storage.delete(key: keySelectedZodiac);
    await _storage.delete(key: keyFailedAttemptCount); // 실패 횟수도 삭제
    if (kDebugMode) print('[SecureStorageService] All user data cleared (tokens, city, zodiac, and failed attempts).');
  }
}