// lib/app/bindings/profile_auth_binding.dart

import 'package:get/get.dart';
import 'package:safe_diary/app/controllers/partner_controller.dart';
import '../controllers/profile_auth_controller.dart';

class ProfileAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileAuthController>(() => ProfileAuthController());
    Get.lazyPut<PartnerController>(() => PartnerController());
  }
}