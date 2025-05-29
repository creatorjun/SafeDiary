// lib/app/views/profile_auth_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_auth_controller.dart';
import '../theme/app_text_styles.dart'; //
import '../theme/app_spacing.dart'; //

class ProfileAuthScreen extends GetView<ProfileAuthController> {
  const ProfileAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 접근 인증', style: textStyleMedium), //
        centerTitle: true,
        automaticallyImplyLeading: true, // 뒤로가기 버튼 자동 생성
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '접근 비밀번호 입력',
                style: textStyleLarge.copyWith(fontWeight: FontWeight.bold), //
                textAlign: TextAlign.center,
              ),
              verticalSpaceMedium, //
              Text(
                '개인정보를 보호하기 위해 설정하신 비밀번호를 입력해주세요.',
                style: textStyleSmall, //
                textAlign: TextAlign.center,
              ),
              verticalSpaceLarge, //
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                autofocus: true,
                textAlign: TextAlign.center,
                style: textStyleMedium, //
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onSubmitted: (_) => controller.verifyPasswordAndNavigate(), // 엔터키로 제출
              ),
              verticalSpaceSmall, //
              Obx(() { // 에러 메시지 표시
                if (controller.errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      controller.errorMessage.value,
                      style: textStyleSmall.copyWith(color: Colors.red), //
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              verticalSpaceMedium, //
              Obx(() { // 로딩 상태에 따라 버튼 또는 인디케이터 표시
                return controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: controller.verifyPasswordAndNavigate,
                  child: Text('확인', style: textStyleMedium.copyWith(color: Colors.white)), //
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}