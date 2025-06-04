// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_user.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes/app_pages.dart';
import 'app/config/app_config.dart';
import 'app/controllers/login_controller.dart';
import 'app/bindings/login_binding.dart';
import 'app/services/secure_storage_service.dart'; // SecureStorageService 임포트
// AuthService와 UserService는 LoginBinding에서 처리하므로 여기서 직접 임포트할 필요는 없습니다.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await AppConfig.loadEnv();

  // Date-formatting 로케일 초기화
  await initializeDateFormatting();

  // --- SecureStorageService 등록 ---
  // 앱 전역에서 사용될 수 있도록 영구 인스턴스로 등록합니다.
  Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
  // ---------------------------------

  // LoginBinding을 통해 LoginController 및 관련 서비스(AuthService, UserService) 등록
  // LoginController가 permanent:true 이므로, LoginBinding도 앱 시작 시점에 호출될 수 있습니다.
  if (!Get.isRegistered<LoginController>()) {
    LoginBinding()
        .dependencies(); // 이 안에서 LoginController, AuthService, UserService가 등록됩니다.
  }
  final LoginController loginController = Get.find<LoginController>();

  // 자동 로그인 시도
  bool autoLoginSuccess = false;
  try {
    autoLoginSuccess = await loginController.tryAutoLoginWithRefreshToken();
  } catch (e) {
    if (kDebugMode) {
      print("[main.dart] Auto login attempt failed: $e");
    }
    autoLoginSuccess = false;
  }

  // Naver/Kakao SDK 초기화
  final String naverAppName = dotenv.env['AppName'] ?? 'YOUR_APP_NAME_DEFAULT';
  final String naverClientId =
      dotenv.env['ClientId'] ?? 'YOUR_NAVER_CLIENT_ID_DEFAULT';
  final String naverClientSecret =
      dotenv.env['ClientSecret'] ?? 'YOUR_NAVER_CLIENT_SECRET_DEFAULT';
  final String? naverUrlScheme = dotenv.env['UrlScheme'];

  final String kakaoNativeAppKey =
      dotenv.env['NativeAppKey'] ?? 'YOUR_KAKAO_NATIVE_APP_KEY_DEFAULT';

  await NaverLoginSDK.initialize(
    clientId: naverClientId,
    clientSecret: naverClientSecret,
    clientName: naverAppName,
    urlScheme: naverUrlScheme,
  );

  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  runApp(MyApp(initialRoute: autoLoginSuccess ? Routes.home : Routes.login));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Safe Diary',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
