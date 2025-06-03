// lib/app/controllers/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import 'login_controller.dart';
import 'partner_controller.dart'; // PartnerController 임포트
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../models/partner_dtos.dart'; // PartnerInvitationResponseDto 사용을 위해 임포트

class ProfileController extends GetxController {
  late final LoginController loginController;
  late final PartnerController partnerController; // PartnerController 인스턴스

  late TextEditingController nicknameController;
  final RxString _initialNickname = ''.obs;
  final RxBool isNicknameChanged = false.obs;

  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final RxBool isCurrentPasswordObscured = true.obs;
  final RxBool isNewPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;

  RxBool get isPasswordSet => loginController.user.isAppPasswordSet.obs;

  Rx<PartnerInvitationResponseDto?> get currentInvitation => partnerController.currentInvitation;
  Rx<PartnerRelationResponseDto?> get currentPartnerRelation => partnerController.currentPartnerRelation;
  RxBool get isPartnerLoading => partnerController.isLoading.obs; // RxBool로 직접 참조
  User get user => loginController.user;


  @override
  void onInit() {
    super.onInit();
    loginController = Get.find<LoginController>();
    partnerController = Get.find<PartnerController>();

    _initialNickname.value = loginController.user.nickname ?? '';
    nicknameController = TextEditingController(text: _initialNickname.value);
    nicknameController.addListener(() {
      isNicknameChanged.value =
          nicknameController.text != _initialNickname.value;
    });

    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    ever(loginController.obs, (_) {
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
    await loginController.updateUserNickname(newNickname);
    if (!loginController.isLoading && loginController.errorMessage.isEmpty) {
      _initialNickname.value = loginController.user.nickname ?? _initialNickname.value;
      isNicknameChanged.value = false;
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

    final success = await loginController.setAppPasswordOnServer(
      loginController.user.isAppPasswordSet ? currentPassword : null,
      newPassword,
    );

    if (success) {
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
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
              Get.back();
              final enteredCurrentPassword =
                  promptCurrentPasswordController.text;
              if (enteredCurrentPassword.isEmpty) {
                Get.snackbar('오류', '현재 비밀번호를 입력해야 해제할 수 있습니다.');
                return;
              }
              final success = await loginController
                  .removeAppPasswordOnServer(enteredCurrentPassword);
              if (success) {
                // 성공
              }
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

  Future<void> generateInvitationCode() async {
    await partnerController.createPartnerInvitationCode();
    if (partnerController.errorMessage.isNotEmpty) {
      Get.snackbar('오류', partnerController.errorMessage); // .value 제거
    }
  }

  Future<void> acceptInvitation(String code) async {
    await partnerController.acceptPartnerInvitation(code);
    if (partnerController.errorMessage.isNotEmpty) {
      Get.snackbar('오류', partnerController.errorMessage); // .value 제거
    }
  }

  Future<void> disconnectPartner() async {
    Get.dialog(
        AlertDialog(
          title: const Text("파트너 연결 끊기"),
          content: const Text("파트너와의 연결을 끊고 모든 대화 내역을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("취소")),
            TextButton(
              onPressed: () async {
                Get.back();
                await partnerController.unfriendPartnerAndClearChat();
                if (partnerController.errorMessage.isNotEmpty) {
                  Get.snackbar('오류', partnerController.errorMessage); // .value 제거
                }
              },
              child: const Text("연결 끊기", style: TextStyle(color: Colors.red)),
            ),
          ],
        )
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