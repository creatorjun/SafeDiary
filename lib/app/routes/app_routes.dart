// lib/app/routes/app_routes.dart

part of 'app_pages.dart'; // app_pages.dart의 일부임을 명시

abstract class Routes {
  Routes._(); // private constructor
  static const login = _Paths.login;
  static const home = _Paths.home;
  static const profile = _Paths.profile;
  static const profileAuth = _Paths.profileAuth; // PROFILE_AUTH 라우트 정의 추가
  static const chat = _Paths.chat; // CHAT 라우트 정의 추가
}

abstract class _Paths {
  _Paths._(); // private constructor
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const profileAuth = '/profile-auth'; // PROFILE_AUTH 경로 문자열 추가
  static const chat = '/chat'; // CHAT 경로 문자열 추가
}