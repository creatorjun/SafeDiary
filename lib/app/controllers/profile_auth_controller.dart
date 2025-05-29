// lib/app/controllers/profile_auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import '../routes/app_pages.dart';

class ProfileAuthController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();
  late TextEditingController passwordController;

  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxInt failedAttemptCount = 0.obs;
  final int maxFailedAttempts = 4;

  @override
  void onInit() {
    super.onInit();
    passwordController = TextEditingController();
  }

  @override
  void onReady() {
    super.onReady();
    _checkPasswordStatusAndProceed();
  }

  void _checkPasswordStatusAndProceed() {
    if (!_loginController.user.isAppPasswordSet) {
      Get.offNamed(Routes.PROFILE);
    }
  }

  Future<void> verifyPasswordAndNavigate() async {
    isLoading.value = true;
    errorMessage.value = '';
    final String enteredPassword = passwordController.text;

    if (enteredPassword.isEmpty) {
      errorMessage.value = '비밀번호를 입력해주세요.';
      isLoading.value = false;
      return;
    }

    final bool isVerified = await _loginController.verifyAppPasswordWithServer(enteredPassword);
    isLoading.value = false;

    if (isVerified) {
      passwordController.clear();
      failedAttemptCount.value = 0;
      Get.offNamed(Routes.PROFILE);
    } else {
      // LoginController에서 설정한 에러 메시지를 사용하거나 여기서 직접 설정
      // LoginController의 errorMessage가 RxString이므로 .value로 접근해야 합니다.
      if (_loginController.errorMessage.isNotEmpty) {
        errorMessage.value = _loginController.errorMessage;
      } else {
        errorMessage.value = '비밀번호가 일치하지 않습니다.'; // 기본 메시지
      }
      failedAttemptCount.value++;
      if (failedAttemptCount.value >= maxFailedAttempts) {
        await _handleMaxFailedAttempts(); // 비동기 호출로 변경
      }
    }
  }

  Future<void> _handleMaxFailedAttempts() async {
    errorMessage.value = '비밀번호를 $maxFailedAttempts회 이상 잘못 입력하셨습니다.';
    // LoginController를 통해 파트너 관계 해제 API 호출
    // 이 작업은 백그라운드에서 수행될 수 있으며, 사용자에게 즉각적인 피드백은 위의 메시지로 제공됩니다.
    await _loginController.unfriendPartnerAndClearChat();

    // 추가적인 UI 처리 (예: 로그인 화면으로 돌려보내기, 앱 사용 제한 등)는 여기에 구현할 수 있습니다.
    Get.offAllNamed(Routes.LOGIN);
    Get.snackbar("보안 조치", "비밀번호를 여러 번 잘못 입력하여 로그아웃됩니다.");
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}