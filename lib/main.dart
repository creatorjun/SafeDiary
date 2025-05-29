// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv.env를 직접 사용하는 부분이 있어서 유지
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_user.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes/app_pages.dart'; // Routes 클래스를 사용하기 위해 임포트
import 'app/config/app_config.dart';
import 'app/controllers/login_controller.dart';
import 'app/bindings/login_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 (AppConfig를 통해)
  await AppConfig.loadEnv();

  // Date-formatting 로케일 초기화
  await initializeDateFormatting();

  // LoginBinding을 통해 LoginController를 GetX에 영구적으로 등록
  if (!Get.isRegistered<LoginController>()) {
    LoginBinding().dependencies();
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

  runApp(
    MyApp(initialRoute: autoLoginSuccess ? Routes.HOME : Routes.LOGIN),
  ); // Routes.HOME, Routes.LOGIN 사용
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
