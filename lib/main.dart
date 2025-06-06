// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_user.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/config/app_config.dart';
import 'app/controllers/login_controller.dart';
import 'app/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize core services and controllers via GetX binding
  InitialBinding().dependencies();

  // Initialize Notification Service (FCM 권한 요청, 핸들러 설정 등)
  await Get.find<NotificationService>().init();

  // Load .env file
  await AppConfig.loadEnv();

  // Initialize date formatting
  await initializeDateFormatting();

  final LoginController loginController = Get.find<LoginController>();

  // Attempt auto-login
  bool autoLoginSuccess = false;
  try {
    autoLoginSuccess = await loginController.tryAutoLoginWithRefreshToken();
  } catch (e) {
    if (kDebugMode) {
      print("[main.dart] Auto login attempt failed: $e");
    }
    autoLoginSuccess = false;
  }

  // Initialize Naver/Kakao SDKs
  final String naverAppName = dotenv.env['AppName'] ?? 'YOUR_APP_NAME_DEFAULT';
  final String naverClientId = dotenv.env['ClientId'] ?? 'YOUR_NAVER_CLIENT_ID_DEFAULT';
  final String naverClientSecret = dotenv.env['ClientSecret'] ?? 'YOUR_NAVER_CLIENT_SECRET_DEFAULT';
  final String? naverUrlScheme = dotenv.env['UrlScheme'];

  final String kakaoNativeAppKey = dotenv.env['NativeAppKey'] ?? 'YOUR_KAKAO_NATIVE_APP_KEY_DEFAULT';

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