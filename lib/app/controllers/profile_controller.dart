// lib/app/controllers/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ProfileController extends GetxController {
  late final LoginController loginController;

  late TextEditingController nicknameController;
  final RxString _initialNickname = ''.obs;
  final RxBool isNicknameChanged = false.obs;

  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final RxBool isCurrentPasswordObscured = true.obs;
  final RxBool isNewPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;

  // isPasswordSet은 이제 LoginController의 user.isAppPasswordSet을 직접 반영합니다.
  RxBool get isPasswordSet => loginController.user.isAppPasswordSet.obs;

  @override
  void onInit() {
    super.onInit();
    loginController = Get.find<LoginController>();

    _initialNickname.value = loginController.user.nickname ?? '';
    nicknameController = TextEditingController(text: _initialNickname.value);
    nicknameController.addListener(() {
      isNicknameChanged.value =
          nicknameController.text != _initialNickname.value;
    });

    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // User 객체가 변경될 때 (예: isAppPasswordSet 변경 시) UI가 반응하도록 listen합니다.
    // GetX의 Rx<User> _user 자체가 변경될 때 반응하므로, isPasswordSet getter가 이를 반영합니다.
    // 만약 isPasswordSet 상태에 따라 특정 컨트롤러 값을 초기화해야 한다면 아래와 같이 listen 할 수 있습니다.
    ever(loginController.obs, (_) {
      // isAppPasswordSet 상태가 변경되면 관련 필드를 초기화할 수 있습니다.
      if (!loginController.user.isAppPasswordSet) {
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      }
    });
  }

  Future<void> saveNickname() async {
    final newNickname = nicknameController.text;
    if (newNickname.trim().isEmpty) {
      Get.snackbar('오류', '닉네임은 비워둘 수 없습니다.');
      return;
    }
    if (newNickname == _initialNickname.value) {
      Get.snackbar('알림', '닉네임이 변경되지 않았습니다.');
      return;
    }
    // LoginController의 닉네임 변경 메소드 호출 (이미 서버 연동 가정)
    await loginController.updateUserNickname(newNickname);
    // 성공 여부는 LoginController 내부의 _isLoading 및 errorMessage로 판단 가능
    if (!loginController.isLoading && loginController.errorMessage.isEmpty) {
      _initialNickname.value = newNickname;
      isNicknameChanged.value = false; // 닉네임 변경 완료 후 상태 업데이트
    }
  }

  Future<void> changeOrSetPassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (loginController.user.isAppPasswordSet && currentPassword.isEmpty) {
      Get.snackbar('오류', '현재 비밀번호를 입력해주세요.');
      return;
    }
    if (newPassword.isEmpty) {
      Get.snackbar('오류', '새 비밀번호를 입력해주세요.');
      return;
    }
    if (newPassword.length < 4) {
      Get.snackbar('오류', '새 비밀번호는 4자 이상이어야 합니다.');
      return;
    }
    if (newPassword != confirmPassword) {
      Get.snackbar('오류', '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.');
      return;
    }

    // LoginController를 통해 서버에 비밀번호 설정/변경 요청
    final success = await loginController.setAppPasswordOnServer(
      loginController.user.isAppPasswordSet ? currentPassword : null,
      newPassword,
    );

    if (success) {
      // 성공 시 비밀번호 입력 필드 초기화
      currentPasswordController.clear(); // 현재 비밀번호 필드도 초기화
      newPasswordController.clear();
      confirmPasswordController.clear();
      // isPasswordSet 상태는 loginController에서 user 객체 업데이트 시 자동으로 반영됨
    }
    // 실패 시 에러 메시지는 LoginController에서 Get.snackbar 등으로 이미 처리되었을 것으로 가정
  }

  Future<void> removePassword() async {
    if (!loginController.user.isAppPasswordSet) {
      Get.snackbar('알림', '설정된 화면 접근 비밀번호가 없습니다.');
      return;
    }

    final TextEditingController promptCurrentPasswordController =
    TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('비밀번호 해제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('비밀번호를 해제하려면 현재 비밀번호를 입력하세요.'),
            verticalSpaceMedium,
            TextField(
              controller: promptCurrentPasswordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(hintText: '현재 비밀번호'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // 다이얼로그 닫기
              final enteredCurrentPassword =
                  promptCurrentPasswordController.text;
              if (enteredCurrentPassword.isEmpty) {
                Get.snackbar('오류', '현재 비밀번호를 입력해야 해제할 수 있습니다.');
                return;
              }
              // LoginController를 통해 서버에 비밀번호 해제 요청
              final success = await loginController
                  .removeAppPasswordOnServer(enteredCurrentPassword);
              if (success) {
                // 성공 시 관련 필드 초기화 (필요하다면)
                // isPasswordSet 상태는 loginController에서 user 객체 업데이트 시 자동으로 반영됨
              }
              // 실패 시 에러 메시지는 LoginController에서 처리
            },
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void handleAccountDeletionRequest() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Wrap(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '회원 탈퇴',
                  style: textStyleLarge.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                verticalSpaceMedium,
                Text(
                  '회원 탈퇴 즉시 사용자의 모든 정보가 파기되며 복구할 수 없습니다. 정말로 탈퇴하시겠습니까?',
                  style: textStyleMedium,
                  textAlign: TextAlign.center,
                ),
                verticalSpaceLarge,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                              color: Get.isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                        ),
                        child: Text(
                          '취소',
                          style: textStyleMedium.copyWith(
                            color: Get.isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    horizontalSpaceMedium,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await loginController.processAccountDeletion();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red.shade600,
                        ),
                        child: Text(
                          '탈퇴 진행',
                          style: textStyleMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpaceSmall,
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void toggleCurrentPasswordVisibility() =>
      isCurrentPasswordObscured.value = !isCurrentPasswordObscured.value;
  void toggleNewPasswordVisibility() =>
      isNewPasswordObscured.value = !isNewPasswordObscured.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;

  @override
  void onClose() {
    nicknameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}