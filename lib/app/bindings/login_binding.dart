// lib/app/bindings/login_binding.dart

import 'package:get/get.dart';
import '../controllers/login_controller.dart'; // LoginController 임포트
import '../services/auth_service.dart'; // AuthService 임포트
import '../services/user_service.dart'; // UserService 임포트

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(() => AuthService());
    Get.lazyPut<UserService>(() => UserService());
    Get.put<LoginController>(LoginController(), permanent: true);
  }
}