// lib/app/views/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../models/user.dart' show LoginPlatform;
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required RxBool isObscured,
    required VoidCallback toggleVisibility,
  }) {
    return Obx(
          () => TextField(
        controller: controller,
        obscureText: isObscured.value,
        style: textStyleMedium, //
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          suffixIcon: IconButton(
            icon: Icon(
              isObscured.value ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 설정', style: textStyleLarge), //
        centerTitle: true,
      ),
      body: Obx(() {
        // LoginController의 user 객체를 Obx 내부에서 접근하여 createdAt 변경 시 UI 업데이트
        final user = controller.loginController.user;
        final formattedCreatedAt = user.formattedCreatedAt; // User 모델에 추가한 getter 사용

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '닉네임 변경',
                  style: textStyleLarge.copyWith( //
                    fontWeight: FontWeight.bold,
                  ),
                ),
                verticalSpaceSmall, //
                TextField(
                  controller: controller.nicknameController,
                  style: textStyleMedium, //
                  decoration: InputDecoration(
                    hintText: '새 닉네임을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    suffixIcon: Obx(
                          () =>
                      controller.isNicknameChanged.value &&
                          controller.nicknameController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.nicknameController.clear();
                        },
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                verticalSpaceMedium, //
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () {
                    if (controller.isNicknameChanged.value) {
                      controller.saveNickname();
                    } else {
                      Get.snackbar('알림', '닉네임이 변경되지 않았습니다.');
                    }
                  },
                  child: Text(
                    '닉네임 저장',
                    style: textStyleMedium.copyWith(color: Colors.white), //
                  ),
                ),
                verticalSpaceLarge, //
                const Divider(),
                verticalSpaceLarge, //
                Text(
                  controller.isPasswordSet.value ? '접근 비밀번호 변경' : '접근 비밀번호 설정',
                  style: textStyleLarge.copyWith( //
                    fontWeight: FontWeight.bold,
                  ),
                ),
                verticalSpaceMedium, //
                if (controller.isPasswordSet.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildPasswordField(
                      controller: controller.currentPasswordController,
                      labelText: '현재 비밀번호',
                      hintText: '현재 설정된 비밀번호 입력',
                      isObscured: controller.isCurrentPasswordObscured,
                      toggleVisibility:
                      controller.toggleCurrentPasswordVisibility,
                    ),
                  ),
                _buildPasswordField(
                  controller: controller.newPasswordController,
                  labelText: '새 비밀번호',
                  hintText: '새 비밀번호 (4자 이상)',
                  isObscured: controller.isNewPasswordObscured,
                  toggleVisibility: controller.toggleNewPasswordVisibility,
                ),
                verticalSpaceMedium, //
                _buildPasswordField(
                  controller: controller.confirmPasswordController,
                  labelText: '새 비밀번호 확인',
                  hintText: '새 비밀번호 다시 입력',
                  isObscured: controller.isConfirmPasswordObscured,
                  toggleVisibility: controller.toggleConfirmPasswordVisibility,
                ),
                verticalSpaceLarge, //
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    controller.changeOrSetPassword();
                  },
                  child: Text(
                    controller.isPasswordSet.value ? '비밀번호 변경' : '비밀번호 설정',
                    style: textStyleMedium.copyWith(color: Colors.white), //
                  ),
                ),
                if (controller.isPasswordSet.value) ...[
                  verticalSpaceMedium, //
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    onPressed: () {
                      controller.removePassword();
                    },
                    child: Text(
                      '접근 비밀번호 해제',
                      style: textStyleMedium.copyWith( //
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
                verticalSpaceLarge, //
                const Divider(),
                verticalSpaceMedium, //
                Text(
                  '로그인 정보',
                  style: textStyleLarge.copyWith( //
                    fontWeight: FontWeight.bold,
                  ),
                ),
                verticalSpaceSmall, //
                Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column( // Column으로 변경하여 Since 날짜 추가
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              user.platform == LoginPlatform.naver
                                  ? const Image(
                                image: Svg('assets/naver_icon.svg'),
                              )
                                  : user.platform == LoginPlatform.kakao
                                  ? const Image(
                                image: Svg('assets/kakao_icon.svg'),
                              )
                                  : const Icon(
                                Icons.device_unknown_outlined,
                                color: Colors.grey,
                                size: 22,
                              ),
                            ),
                            horizontalSpaceSmall, //
                            Text(
                              user.platform == LoginPlatform.naver
                                  ? "네이버 로그인"
                                  : user.platform == LoginPlatform.kakao
                                  ? "카카오 로그인"
                                  : (user.platform.name.capitalizeFirst ?? '정보 없음'),
                              style: textStyleMedium, //
                            ),
                          ],
                        ),
                        if (formattedCreatedAt.isNotEmpty) ...[ // createdAt 정보가 있을 경우에만 표시
                          verticalSpaceSmall, //
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Since: $formattedCreatedAt',
                              style: textStyleSmall.copyWith(color: Colors.grey.shade600), //
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                verticalSpaceMedium, //
                Card(
                  elevation: 2.0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                    title: Text(
                      '회원 탈퇴',
                      style: textStyleMedium.copyWith( //
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade600, size: 16),
                    onTap: () {
                      controller.handleAccountDeletionRequest();
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  ),
                ),
                verticalSpaceLarge, //
              ],
            ),
          ),
        );
      }),
    );
  }
}