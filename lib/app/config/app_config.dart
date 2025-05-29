// lib/app/config/app_config.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Private constructor
  AppConfig._();

  // .env 파일이 로드되었는지 확인하는 플래그
  static bool _isEnvLoaded = false;

  /// 앱이 시작될 때 .env 파일을 로드합니다. (main.dart에서 호출)
  /// 이미 로드된 경우 다시 로드하지 않습니다.
  static Future<void> loadEnv() async {
    if (_isEnvLoaded) {
      if (kDebugMode) {
        print('AppConfig: .env file already loaded.');
      }
      return;
    }
    try {
      // --- 경로 수정 ---
      await dotenv.load(fileName: "lib/app/config/.env"); // <<< 경로 변경됨
      _isEnvLoaded = true;
      if (kDebugMode) {
        print(
          'AppConfig: .env file loaded successfully from lib/app/config/.env.',
        );
        // 로드된 ApiUrl 테스트 출력 (선택적)
        // print('AppConfig: ApiUrl after load: ${dotenv.env['ApiUrl']}');
      }
    } catch (e) {
      _isEnvLoaded = false; // 로드 실패 시 플래그를 false로 설정
      if (kDebugMode) {
        print(
          'AppConfig: Error loading .env file from lib/app/config/.env: $e',
        );
      }
    }
  }

  /// .env 파일에서 'ApiUrl' 값을 가져옵니다.
  static String? get apiUrl {
    if (!_isEnvLoaded) {
      if (kDebugMode) {
        print(
          'AppConfig: Warning! Accessed apiUrl before .env was loaded or load failed. Call AppConfig.loadEnv() in main.dart.',
        );
      }
      // .env 로드가 실패했거나 호출 전이면 null 반환 또는 예외 처리 가능
      // return null;
    }

    String? url;
    if (Platform.isAndroid) {
      url = dotenv.env['ApiUrlDev'];
      if (kDebugMode && url != null) {
        print('AppConfig: Using ApiUrlDev for Android: $url');
      }
    }

    // ApiUrlDev가 없거나, 안드로이드가 아닌 경우 ApiUrl 사용
    url ??= dotenv.env['ApiUrl'];

    if (kDebugMode && url == null) {
      print(
        'AppConfig: Warning! ApiUrl (and ApiUrlDev for Android) not found in .env file.',
      );
    }

    return url;
  }
}
