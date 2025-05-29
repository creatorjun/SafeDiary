// lib/app/bindings/profile_binding.dart

import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
// LoginController는 이미 AppBinding 또는 HomeBinding 등 상위 레벨에서 put 되어있다고 가정합니다.
// 만약 그렇지 않다면 여기서 LoginController도 함께 바인딩해야 할 수 있습니다.

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}