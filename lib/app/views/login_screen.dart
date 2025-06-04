// lib/app/views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import '../controllers/login_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  Widget _buildNaverLoginButton(BuildContext context, LoginController controller) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF03C75A),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        controller.loginWithNaver();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: Svg('assets/naver_icon.svg'),
            width: 24,
            height: 24,
          ),
          horizontalSpaceSmall,
          Text(
            '네이버 로그인',
            style: textStyleLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildKakaoLoginButton(BuildContext context, LoginController controller) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFEE500),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        controller.loginWithKakao();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: Svg('assets/kakao_icon.svg'),
            width: 24,
            height: 24,
          ),
          horizontalSpaceSmall,
          Text(
            '카카오 로그인',
            style: textStyleLarge.copyWith(color: const Color(0xFF191919)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileView(BuildContext context, LoginController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${controller.user.nickname ?? '사용자'}님, 환영합니다!',
          style: textStyleLarge.copyWith(fontSize: 20.0),
          textAlign: TextAlign.center,
        ),
        verticalSpaceMedium,
        Text(
          '로그인 플랫폼: ${controller.user.platform.name}',
          style: textStyleSmall,
          textAlign: TextAlign.center,
        ),
        verticalSpaceLarge,
        ElevatedButton(
          onPressed: () {
            controller.logout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            '로그아웃',
            style: textStyleMedium.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        return Container( // 배경 이미지를 위한 Container 추가
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/login_back.png"), // 배경 이미지 경로
              fit: BoxFit.cover, // 이미지가 화면을 꽉 채우도록 설정
            ),
          ),
          child: Center( // 기존 내용을 가운데 정렬하기 위해 Center 위젯 추가
            child: _buildLoginContent(context),
          ),
        );
      }),
    );
  }

  Widget _buildLoginContent(BuildContext context) { // 기존 body 내용을 별도 메서드로 추출
    if (controller.isLoading) {
      return const CircularProgressIndicator();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72.0),
                child: Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (controller.errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                controller.errorMessage,
                                style: textStyleSmall.copyWith(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (!controller.isLoggedIn.value) ...[
                            _buildNaverLoginButton(context, controller),
                            verticalSpaceMedium,
                            _buildKakaoLoginButton(context, controller),
                          ] else ...[
                            _buildUserProfileView(context, controller),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}