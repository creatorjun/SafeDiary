// lib/app/bindings/login_binding.dart

import 'package:get/get.dart';
import '../controllers/login_controller.dart'; // LoginController 임포트

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LoginController>(LoginController(), permanent: true);
  }
}