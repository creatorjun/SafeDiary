// lib/app/controllers/profile_auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../controllers/partner_controller.dart';
import '../routes/app_pages.dart';
import '../services/secure_storage_service.dart'; // SecureStorageService 임포트

class ProfileAuthController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();
  final PartnerController _partnerController = Get.find<PartnerController>();
  final SecureStorageService _secureStorageService = Get.find<SecureStorageService>(); // SecureStorageService 주입
  late TextEditingController passwordController;

  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  // RxInt failedAttemptCount = 0.obs; // 이제 SecureStorage에서 관리합니다.
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

  void _checkPasswordStatusAndProceed() async {
    // 앱 비밀번호가 설정되어 있지 않으면 바로 프로필 화면으로 이동
    if (!_loginController.user.isAppPasswordSet) {
      await _secureStorageService.clearFailedAttemptCount(); // 비밀번호 미설정 시에도 실패 횟수 초기화
      Get.offNamed(Routes.profile);
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

    // LoginController를 통해 앱 비밀번호 검증 API 호출
    final bool isVerified = await _loginController.verifyAppPasswordWithServer(enteredPassword);

    if (isVerified) {
      await _secureStorageService.clearFailedAttemptCount(); // 성공 시 실패 횟수 초기화
      passwordController.clear();
      isLoading.value = false;
      Get.offNamed(Routes.profile); // 인증 성공 시 프로필 화면으로 이동
    } else {
      int currentAttempts = await _secureStorageService.getFailedAttemptCount();
      currentAttempts++;
      await _secureStorageService.saveFailedAttemptCount(currentAttempts);

      // LoginController에서 설정한 에러 메시지를 사용하거나 여기서 직접 설정
      if (_loginController.errorMessage.isNotEmpty) {
        errorMessage.value = _loginController.errorMessage;
      } else {
        errorMessage.value = '비밀번호가 일치하지 않습니다.'; // 기본 메시지
      }
      passwordController.clear(); // 실패 시 입력 필드 초기화

      if (currentAttempts >= maxFailedAttempts) {
        await _handleMaxFailedAttempts();
      }
      isLoading.value = false;
    }
  }

  Future<void> _handleMaxFailedAttempts() async {
    errorMessage.value = '비밀번호를 $maxFailedAttempts회 이상 잘못 입력하셨습니다. 보안 조치로 로그아웃됩니다.';
    Get.snackbar(
      "보안 조치",
      "비밀번호를 여러 번 잘못 입력하여 로그아웃됩니다.",
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12.0),
    );

    if (_loginController.user.partnerUid != null && _loginController.user.partnerUid!.isNotEmpty) {
      await _partnerController.unfriendPartnerAndClearChat();
    }

    await _secureStorageService.clearFailedAttemptCount();
    await _loginController.logout();
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}