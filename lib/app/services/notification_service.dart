// lib/app/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../firebase_options.dart';
import '../controllers/login_controller.dart';
import 'package:firebase_core/firebase_core.dart';

// Background handler는 반드시 최상위 함수여야 합니다.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서 다른 Firebase 서비스를 사용하려면 초기화가 필요할 수 있습니다.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print("[NotificationService] Handling a background message: ${message.messageId}");
  }
}

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Android 알림 채널 정의
  final AndroidNotificationChannel _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // 채널 ID
    '중요 알림', // 채널 이름
    description: '중요한 알림을 위한 채널입니다.', // 채널 설명
    importance: Importance.high,
  );

  /// 서비스 초기화 메서드
  Future<NotificationService> init() async {
    await _setupLocalNotifications();
    await _setupFirebaseListeners();
    return this;
  }

  /// 로컬 알림 설정 (Android 채널 생성 포함)
  Future<void> _setupLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // 기본 앱 아이콘 사용

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('[NotificationService] Local notification tapped with payload: ${response.payload}');
        }
        // 여기서 페이로드(payload)를 사용하여 특정 화면으로 이동하는 로직을 구현할 수 있습니다.
      },
    );
  }

  /// Firebase 메시징 리스너 설정
  Future<void> _setupFirebaseListeners() async {
    // iOS 포그라운드 알림 설정
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 백그라운드 핸들러 연결
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 포그라운드 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 알림 클릭 시 앱 열기 (앱이 백그라운드 상태일 때)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[NotificationService] Message clicked and app opened!');
        print('[NotificationService] Message data: ${message.data}');
      }
      // 메시지 데이터에 따라 특정 화면으로 이동
    });

    // 알림 클릭 시 앱 열기 (앱이 종료된 상태일 때)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('[NotificationService] Terminated App: Initial message received.');
          print('[NotificationService] Message data: ${message.data}');
        }
        // 메시지 데이터에 따라 특정 화면으로 이동
      }
    });

    // FCM 토큰 갱신 감지
    _messaging.onTokenRefresh.listen(_updateTokenOnServer);

    // 초기 FCM 토큰 가져오기
    _messaging.getToken().then((token) {
      if (token != null) {
        _updateTokenOnServer(token);
      }
    });
  }

  /// 포그라운드 메시지 처리 및 로컬 알림 표시
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] Got a message whilst in the foreground!');
    }
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    // 알림(notification) 페이로드가 있고, Android 환경일 때 로컬 알림을 띄웁니다.
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher', // 안드로이드 알림 아이콘
          ),
        ),
        payload: message.data.toString(), // 알림 클릭 시 전달할 데이터 (선택 사항)
      );
    }
  }

  /// FCM 토큰을 서버로 전송
  void _updateTokenOnServer(String token) {
    if (kDebugMode) {
      print('[NotificationService] FCM Token: $token');
    }
    // LoginController가 등록되어 있는지 확인 후 사용
    if (Get.isRegistered<LoginController>()) {
      final loginController = Get.find<LoginController>();
      if (loginController.isLoggedIn.value) {
        loginController.sendFcmTokenToServer(token);
      } else {
        if (kDebugMode) {
          print('[NotificationService] User not logged in, FCM token will be sent after login.');
        }
      }
    }
  }
}