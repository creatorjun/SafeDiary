// lib/app/routes/app_pages.dart

import 'package:get/get.dart';

import '../views/login_screen.dart';
import '../bindings/login_binding.dart';

import '../views/home_screen.dart';
import '../bindings/home_binding.dart';

import '../views/profile_screen.dart';
import '../bindings/profile_binding.dart';

import '../views/profile_auth_screen.dart';
import '../bindings/profile_auth_binding.dart';

// ChatScreen 및 ChatBinding 임포트 추가
import '../views/chat_screen.dart';
import '../bindings/chat_binding.dart';


part 'app_routes.dart'; // app_routes.dart 파일을 현재 파일의 일부로 포함

class AppPages {
  AppPages._(); // private constructor로, 이 클래스의 직접적인 인스턴스화 방지

  static const initial = Routes.login; // 앱 시작 시 첫 화면 경로

  static final routes = [
    GetPage(
      name: _Paths.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.profileAuth, // 개인정보 접근 인증 화면 경로
      page: () => const ProfileAuthScreen(), // 화면 위젯
      binding: ProfileAuthBinding(), // 바인딩
    ),
    GetPage(
      name: _Paths.profile,
      page: () => ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.chat, // 채팅 화면 경로
      page: () => const ChatScreen(), // 화면 위젯
      binding: ChatBinding(), // 바인딩
    ),
  ];
}