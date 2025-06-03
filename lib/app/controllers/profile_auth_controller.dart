// lib/app/controllers/profile_auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import 'partner_controller.dart'; // PartnerController 임포트
import '../routes/app_pages.dart';

class ProfileAuthController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();
  // PartnerController 인스턴스를 가져옵니다. PartnerBinding을 통해 등록되어 있어야 합니다.
  final PartnerController _partnerController = Get.find<PartnerController>();
  late TextEditingController passwordController;

  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  final RxInt failedAttemptCount = 0.obs;
  final int maxFailedAttempts = 4; // 예시 값, 실제 정책에 맞게 조정

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
    // 앱 비밀번호가 설정되어 있지 않으면 바로 프로필 화면으로 이동
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

    // LoginController를 통해 앱 비밀번호 검증 API 호출
    final bool isVerified = await _loginController.verifyAppPasswordWithServer(enteredPassword);
    isLoading.value = false;

    if (isVerified) {
      passwordController.clear();
      failedAttemptCount.value = 0;
      Get.offNamed(Routes.PROFILE); // 인증 성공 시 프로필 화면으로 이동
    } else {
      // LoginController에서 설정한 에러 메시지를 사용하거나 여기서 직접 설정
      if (_loginController.errorMessage.isNotEmpty) {
        errorMessage.value = _loginController.errorMessage;
      } else {
        errorMessage.value = '비밀번호가 일치하지 않습니다.'; // 기본 메시지
      }
      passwordController.clear(); // 실패 시 입력 필드 초기화
      failedAttemptCount.value++;
      if (failedAttemptCount.value >= maxFailedAttempts) {
        await _handleMaxFailedAttempts();
      }
    }
  }

  Future<void> _handleMaxFailedAttempts() async {
    errorMessage.value = '비밀번호를 $maxFailedAttempts회 이상 잘못 입력하셨습니다. 보안 조치로 로그아웃됩니다.';
    Get.snackbar("보안 조치", "비밀번호를 여러 번 잘못 입력하여 파트너 관계가 해제(설정된 경우)되고 로그아웃됩니다.", duration: const Duration(seconds: 5));

    // PartnerController를 통해 파트너 관계 해제 API 호출
    // 사용자가 파트너와 연결되어 있을 경우에만 호출
    if (_loginController.user.partnerUid != null && _loginController.user.partnerUid!.isNotEmpty) {
      await _partnerController.unfriendPartnerAndClearChat();
      // PartnerController의 unfriendPartnerAndClearChat 내부에서 partnerUid가 null로 업데이트 되고,
      // 이는 LoginController의 user.value.partnerUid에도 반영됩니다.
    }

    // LoginController를 통해 로그아웃 처리
    await _loginController.logout();
    // 로그아웃 후에는 로그인 화면으로 이동시키거나 앱을 초기 상태로 되돌립니다.
    // Get.offAllNamed(Routes.LOGIN); // logout 메서드 내부에서 이미 처리하고 있음
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}