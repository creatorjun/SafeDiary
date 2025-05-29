import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import '../controllers/login_controller.dart';
import '../theme/app_spacing.dart'; // 미리 정의된 간격 사용
import '../theme/app_text_styles.dart'; // 미리 정의된 텍스트 스타일 사용

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  // 네이버 로그인 버튼 생성 위젯
  Widget _buildNaverLoginButton(BuildContext context, LoginController controller) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF03C75A), // 네이버 색상
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
          horizontalSpaceSmall, // 미리 정의된 가로 간격 사용
          Text(
            '네이버 로그인',
            style: textStyleLarge.copyWith(color: Colors.white), // 미리 정의된 텍스트 스타일 사용
          ),
        ],
      ),
    );
  }

  // 카카오 로그인 버튼 생성 위젯
  Widget _buildKakaoLoginButton(BuildContext context, LoginController controller) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFEE500), // 카카오 색상
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
          horizontalSpaceSmall, // 미리 정의된 가로 간격 사용
          Text(
            '카카오 로그인',
            style: textStyleLarge.copyWith(color: const Color(0xFF191919)), // 미리 정의된 텍스트 스타일 사용
          ),
        ],
      ),
    );
  }

  // 로그인 성공 시 사용자 정보 표시 위젯 (수정됨)
  Widget _buildUserProfileView(BuildContext context, LoginController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${controller.user.nickname ?? '사용자'}님, 환영합니다!', //
          style: textStyleLarge.copyWith(fontSize: 20.0), // textStyleLarge 기반으로 크기 조정
          textAlign: TextAlign.center,
        ),
        verticalSpaceMedium, // 간격 조정 (기존 profileImageUrl과 email 사이 간격 등을 고려)
        // profileImageUrl 관련 CircleAvatar 제거됨
        // email 관련 Text 제거됨
        Text(
          '로그인 플랫폼: ${controller.user.platform.name}', //
          style: textStyleSmall, // 미리 정의된 텍스트 스타일 사용
          textAlign: TextAlign.center,
        ),
        verticalSpaceLarge, // 미리 정의된 세로 간격 사용
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
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
                        SizedBox(height: constraints.maxHeight * 0.7),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (controller.errorMessage.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0), // 또는 verticalSpaceMedium
                                  child: Text(
                                    controller.errorMessage,
                                    style: textStyleSmall.copyWith(color: Colors.red), //
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (!controller.isLoggedIn.value) ...[ //
                                _buildNaverLoginButton(context, controller),
                                verticalSpaceMedium, // 미리 정의된 세로 간격 사용
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
      }),
    );
  }
}