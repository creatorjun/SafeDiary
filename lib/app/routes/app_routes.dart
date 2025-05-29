// lib/app/routes/app_routes.dart

part of 'app_pages.dart'; // app_pages.dart의 일부임을 명시

abstract class Routes {
  Routes._(); // private constructor
  static const LOGIN = _Paths.LOGIN;
  static const HOME = _Paths.HOME;
  static const PROFILE = _Paths.PROFILE;
  static const PROFILE_AUTH = _Paths.PROFILE_AUTH; // PROFILE_AUTH 라우트 정의 추가
}

abstract class _Paths {
  _Paths._(); // private constructor
  static const LOGIN = '/login';
  static const HOME = '/home';
  static const PROFILE = '/profile';
  static const PROFILE_AUTH = '/profile-auth'; // PROFILE_AUTH 경로 문자열 추가
}