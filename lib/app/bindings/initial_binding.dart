// lib/app/bindings/initial_binding.dart

import 'package:get/get.dart';
import 'package:safe_diary/app/controllers/login_controller.dart';
import 'package:safe_diary/app/controllers/partner_controller.dart';
import 'package:safe_diary/app/services/notification_service.dart';
import 'package:safe_diary/app/services/secure_storage_service.dart';
import 'package:safe_diary/app/services/user_service.dart';

import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core Services (앱 생명주기 동안 유지)
    Get.put(SecureStorageService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.lazyPut(() => AuthService());
    Get.lazyPut(() => UserService());


    // Core Controllers (앱 생명주기 동안 유지)
    Get.put(LoginController(), permanent: true);
    Get.put(PartnerController(), permanent: true);
  }
}