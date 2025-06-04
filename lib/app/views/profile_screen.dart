// lib/app/views/profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 사용
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅

import '../controllers/profile_controller.dart';
import '../models/user.dart' show LoginPlatform;
import '../routes/app_pages.dart'; // Routes 사용을 위해 임포트
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ProfileScreen extends GetView<ProfileController> {
  ProfileScreen({super.key});

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
        style: textStyleMedium,
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

  Widget _buildPartnerSection(BuildContext context) {
    return Obx(() {
      if (controller.isPartnerLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final user = controller.user; // LoginController의 User 객체
      final partnerRelation =
          controller.currentPartnerRelation.value; // PartnerController의 상세 관계 정보
      final invitation = controller.currentInvitation.value;

      // 1. 파트너와 이미 연결된 경우 (user.partnerUid 존재를 우선 확인)
      if (user.partnerUid != null && user.partnerUid!.isNotEmpty) {
        String partnerNickname = '파트너'; // 기본값
        final String partnerUserUid = user.partnerUid!;

        // 상세 정보에서 닉네임 가져오기 시도
        if (partnerRelation?.partnerUser.nickname != null &&
            partnerRelation!.partnerUser.nickname!.isNotEmpty) {
          partnerNickname = partnerRelation.partnerUser.nickname!;
        }
        // LoginController의 User 객체에 저장된 파트너 닉네임 사용 (fallback)
        else if (user.partnerNickname != null && user.partnerNickname!.isNotEmpty) {
          partnerNickname = user.partnerNickname!;
        }


        String formattedPartnerSince = '날짜 정보 없음';
        if (partnerRelation != null) {
          try {
            DateTime? partnerSinceDate =
            DateTime.parse(partnerRelation.partnerSince).toLocal();
            formattedPartnerSince = DateFormat(
              'yy년 MM월 dd일',
              'ko_KR',
            ).format(partnerSinceDate);
          } catch (e) {
            if (kDebugMode) {
              print(
                'Error parsing partnerSince date: ${partnerRelation.partnerSince}',
              );
            }
          }
        }

        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연결된 파트너: $partnerNickname',
                  style: textStyleMedium.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                verticalSpaceSmall,
                Text('UID: $partnerUserUid', style: textStyleSmall.copyWith(color: Colors.grey.shade600)),
                if (partnerRelation != null && formattedPartnerSince != '날짜 정보 없음')
                  Text('연결 시작일: $formattedPartnerSince', style: textStyleSmall.copyWith(color: Colors.grey.shade600)),
                verticalSpaceMedium,
                ElevatedButton.icon( // 채팅 시작 버튼
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text(
                    '$partnerNickname님과 채팅하기',
                    style: textStyleSmall.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    Get.toNamed(
                      Routes.CHAT,
                      arguments: {
                        'partnerUid': partnerUserUid,
                        'partnerNickname': partnerNickname,
                      },
                    );
                  },
                ),
                verticalSpaceSmall,
                OutlinedButton.icon( // 연결 끊기 버튼 스타일 변경
                  icon: Icon(Icons.link_off_rounded, size: 18, color: Colors.red.shade700),
                  label: Text(
                    '파트너 연결 끊기',
                    style: textStyleSmall.copyWith(color: Colors.red.shade700),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    controller.disconnectPartner();
                  },
                ),
              ],
            ),
          ),
        );
      }
      // 2. (파트너 없는 경우) 생성된 초대 코드가 있는 경우
      else if (invitation != null) {
        DateTime? expiresAtDate;
        try {
          expiresAtDate = DateTime.parse(invitation.expiresAt).toLocal();
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing expiresAt date: ${invitation.expiresAt}');
          }
        }
        String formattedExpiresAt =
        expiresAtDate != null
            ? DateFormat('yy/MM/dd HH:mm', 'ko_KR').format(expiresAtDate)
            : '알 수 없음';

        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '생성된 파트너 초대 코드',
                  style: textStyleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                verticalSpaceSmall,
                TextField(
                  controller: TextEditingController(
                    text: invitation.invitationId,
                  ),
                  readOnly: true,
                  style: textStyleSmall,
                  decoration: InputDecoration(
                    // labelText: '초대 코드',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: '코드 복사',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: invitation.invitationId),
                        );
                        Get.snackbar('복사 완료', '초대 코드가 클립보드에 복사되었습니다.');
                      },
                    ),
                  ),
                ),
                verticalSpaceSmall,
                Text('만료 시간: $formattedExpiresAt', style: textStyleSmall.copyWith(color: Colors.grey.shade600)),
                verticalSpaceMedium,
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    controller.generateInvitationCode(); // 새 코드 생성
                  },
                  child: const Text('새 코드로 다시 생성'),
                ),
              ],
            ),
          ),
        );
      }
      // 3. 파트너도 없고, 생성된 초대 코드도 없는 경우
      else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: () {
                controller.generateInvitationCode();
              },
              child: Text(
                '파트너 초대 코드 생성하기',
                style: textStyleMedium.copyWith(color: Colors.white),
              ),
            ),
            verticalSpaceMedium,
            TextField(
              controller: _invitationCodeInputController,
              style: textStyleMedium,
              decoration: InputDecoration(
                hintText: '받은 초대 코드 입력',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  tooltip: '초대 수락',
                  onPressed: () {
                    final code = _invitationCodeInputController.text.trim();
                    if (code.isNotEmpty) {
                      controller.acceptInvitation(code);
                      _invitationCodeInputController.clear();
                    } else {
                      Get.snackbar('오류', '초대 코드를 입력해주세요.');
                    }
                  },
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  final TextEditingController _invitationCodeInputController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 설정', style: textStyleLarge),
        centerTitle: true,
      ),
      body: Obx(() {
        final user = controller.user;
        final formattedCreatedAt = user.formattedCreatedAt;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '닉네임 변경',
                  style: textStyleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                verticalSpaceSmall,
                TextField(
                  controller: controller.nicknameController,
                  style: textStyleMedium,
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
                          controller.nicknameController.text = controller.user.nickname ?? '';
                        },
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                verticalSpaceMedium,
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                    style: textStyleMedium.copyWith(color: Colors.white),
                  ),
                ),
                verticalSpaceLarge,
                const Divider(),
                verticalSpaceLarge,
                Text(
                  controller.isPasswordSet.value ? '접근 비밀번호 변경' : '접근 비밀번호 설정',
                  style: textStyleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                verticalSpaceMedium,
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
                verticalSpaceMedium,
                _buildPasswordField(
                  controller: controller.confirmPasswordController,
                  labelText: '새 비밀번호 확인',
                  hintText: '새 비밀번호 다시 입력',
                  isObscured: controller.isConfirmPasswordObscured,
                  toggleVisibility: controller.toggleConfirmPasswordVisibility,
                ),
                verticalSpaceLarge,
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    controller.changeOrSetPassword();
                  },
                  child: Text(
                    controller.isPasswordSet.value ? '비밀번호 변경' : '비밀번호 설정',
                    style: textStyleMedium.copyWith(color: Colors.white),
                  ),
                ),
                if (controller.isPasswordSet.value) ...[
                  verticalSpaceMedium,
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    onPressed: () {
                      controller.removePassword();
                    },
                    child: Text(
                      '접근 비밀번호 해제',
                      style: textStyleMedium.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
                verticalSpaceLarge,
                const Divider(),
                verticalSpaceLarge,
                Text(
                  '파트너 연결',
                  style: textStyleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                verticalSpaceMedium,
                _buildPartnerSection(context),
                verticalSpaceLarge,
                const Divider(),
                verticalSpaceMedium,
                Text(
                  '로그인 정보',
                  style: textStyleLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                verticalSpaceSmall,
                Card(
                  elevation: 2.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
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
                                  ? Image(
                                image: Svg('assets/naver_icon.svg', color: Colors.green.shade600),
                              )
                                  : user.platform == LoginPlatform.kakao
                                  ? const Image(
                                image: Svg('assets/kakao_icon.svg'),
                              )
                                  : Icon(
                                Icons.device_unknown_outlined,
                                color: Colors.grey.shade700,
                                size: 22,
                              ),
                            ),
                            horizontalSpaceSmall,
                            Text(
                              user.platform == LoginPlatform.naver
                                  ? "네이버 로그인"
                                  : user.platform == LoginPlatform.kakao
                                  ? "카카오 로그인"
                                  : (user.platform.name.capitalizeFirst ??
                                  '정보 없음'),
                              style: textStyleMedium.copyWith(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        if (formattedCreatedAt.isNotEmpty) ...[
                          verticalSpaceSmall,
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              '가입일: $formattedCreatedAt',
                              style: textStyleSmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                verticalSpaceMedium,
                Card(
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: Colors.red.shade100)
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red.shade600,
                    ),
                    title: Text(
                      '회원 탈퇴',
                      style: textStyleMedium.copyWith(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade500,
                      size: 16,
                    ),
                    onTap: () {
                      controller.handleAccountDeletionRequest();
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                  ),
                ),
                verticalSpaceLarge,
              ],
            ),
          ),
        );
      }),
    );
  }
}