// lib/main.dart

import 'package:firebase_core/firebase_core.dart'; // Firebase Core 임포트
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging 임포트
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
import 'app/services/secure_storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("[main.dart] Handling a background message: ${message.messageId}");
    print('[main.dart] Background Message data: ${message.data}');
    if (message.notification != null) {
      print('[main.dart] Background Message notification: ${message.notification!.title} / ${message.notification!.body}');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 앱 초기화
  await Firebase.initializeApp();

  // FCM 권한 요청 (iOS 및 Web)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[main.dart] User granted FCM permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('[main.dart] User granted provisional FCM permission');
    } else {
      print('[main.dart] User declined or has not accepted FCM permission');
    }
  }

  // 백그라운드 메시지 핸들러 설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // .env 파일 로드
  await AppConfig.loadEnv();

  // Date-formatting 로케일 초기화
  await initializeDateFormatting();

  // --- SecureStorageService 등록 ---
  Get.put<SecureStorageService>(SecureStorageService(), permanent: true);

  // --- UserService 등록 (LoginBinding에서 이미 처리하지만, 명시적으로 여기서 할 수도 있음) ---
  // Get.lazyPut<UserService>(() => UserService()); // LoginBinding에서 처리

  // LoginBinding을 통해 LoginController 및 관련 서비스(AuthService, UserService) 등록
  if (!Get.isRegistered<LoginController>()) {
    LoginBinding().dependencies();
  }
  final LoginController loginController = Get.find<LoginController>();

  // FCM 토큰 가져오기 및 서버 전송 로직
  try {
    String? fcmToken = await messaging.getToken();
    if (kDebugMode) {
      print("[main.dart] FCM Token: $fcmToken");
    }
    if (fcmToken != null && loginController.isLoggedIn.value) {
      // 로그인이 되어 있는 경우에만 즉시 서버로 전송
      await loginController.sendFcmTokenToServer(fcmToken);
    } else if (fcmToken != null) {
      // TODO: 로그인이 안 되어있다면, 토큰을 임시 저장했다가 로그인 성공 후 전송하는 로직 고려 가능
      if (kDebugMode) {
        print("[main.dart] User not logged in, FCM token not sent to server yet: $fcmToken");
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print("[main.dart] Error getting FCM token: $e");
    }
  }

  // FCM 토큰 갱신 리스너
  messaging.onTokenRefresh.listen((fcmToken) {
    if (kDebugMode) {
      print("[main.dart] FCM Token Refreshed: $fcmToken");
    }
    if (loginController.isLoggedIn.value) {
      // 로그인이 되어 있는 경우에만 즉시 서버로 전송
      loginController.sendFcmTokenToServer(fcmToken);
    } else {
      // TODO: 토큰 갱신 시점에도 로그인이 안 되어있다면, 임시 저장 후 로그인 성공 시 전송
      if (kDebugMode) {
        print("[main.dart] User not logged in during token refresh, FCM token not sent to server yet: $fcmToken");
      }
    }
  }).onError((err) {
    if (kDebugMode) {
      print("[main.dart] FCM onTokenRefresh Error: $err");
    }
  });


  // 자동 로그인 시도
  bool autoLoginSuccess = false;
  try {
    autoLoginSuccess = await loginController.tryAutoLoginWithRefreshToken();
    if (autoLoginSuccess) {
      // 자동 로그인 성공 후에도 FCM 토큰을 한번 더 확인하여 전송 (토큰이 변경되었을 수 있음)
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        await loginController.sendFcmTokenToServer(fcmToken);
      }
    }
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