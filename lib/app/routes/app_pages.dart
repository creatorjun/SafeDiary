// lib/app/routes/app_pages.dart

import 'package:get/get.dart';

import '../views/login_screen.dart';
import '../bindings/login_binding.dart';

import '../views/home_screen.dart';
import '../bindings/home_binding.dart';

import '../views/profile_screen.dart';
import '../bindings/profile_binding.dart';

// ProfileAuthScreen 관련 파일 임포트
import '../views/profile_auth_screen.dart';
import '../bindings/profile_auth_binding.dart';


part 'app_routes.dart'; // app_routes.dart 파일을 현재 파일의 일부로 포함

class AppPages {
  AppPages._(); // private constructor로, 이 클래스의 직접적인 인스턴스화 방지

  static const INITIAL = Routes.LOGIN; // 앱 시작 시 첫 화면 경로

  static final routes = [
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    // --- ProfileAuthScreen 라우트 추가 ---
    GetPage(
      name: _Paths.PROFILE_AUTH, // 개인정보 접근 인증 화면 경로
      page: () => const ProfileAuthScreen(), // 화면 위젯
      binding: ProfileAuthBinding(), // 바인딩
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileScreen(),
      binding: ProfileBinding(),
    ),
  ];
}