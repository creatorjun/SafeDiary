import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // 날짜 및 시간 포맷팅을 위해 추가

import '../controllers/chat_controller.dart';
import '../controllers/login_controller.dart';
import '../models/chat_models.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // LoginController를 가져와 현재 사용자 UID를 쉽게 참조할 수 있도록 합니다.
    // ChatController 내부에서도 _currentUserUid로 접근 가능하지만,
    // UI 로직에서 직접적인 비교가 필요할 수 있으므로 여기서도 가져옵니다.
    final LoginController loginController = Get.find<LoginController>();
    final String currentUserUid = loginController.user.id ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.chatPartnerNickname, // 컨트롤러에서 파트너 닉네임 가져오기
          style: textStyleMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "메시지 새로고침",
            onPressed: () {
              controller.fetchInitialMessages();
            },
          ),
          // TODO: 채팅방 추가 옵션 (예: 검색, 나가기 등) 버튼 추가 가능
        ],
      ),
      body: Column(
        children: [
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty && controller.messages.isEmpty) {
              return Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        verticalSpaceMedium,
                        Text(
                          "메시지를 불러오는 중 오류 발생",
                          style: textStyleMedium.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        verticalSpaceSmall,
                        Text(
                          controller.errorMessage.value,
                          style: textStyleSmall.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.messages.isEmpty && !controller.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "아직 메시지가 없습니다.\n첫 메시지를 보내보세요!",
                      style: textStyleSmall.copyWith(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                reverse: true, // 새 메시지가 아래에, 이전 메시지가 위에 오도록
                padding: const EdgeInsets.all(8.0),
                itemCount: controller.messages.length + (controller.isFetchingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (controller.isFetchingMore.value && index == controller.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                    );
                  }
                  final message = controller.messages[index];
                  final bool isMe = message.senderUid == currentUserUid;
                  return _buildMessageBubble(context, message, isMe);
                },
              );
            }),
          ),
          _buildMessageInputField(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, bool isMe) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant;
    final radius = isMe
        ? const BorderRadius.only(
      topLeft: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    )
        : const BorderRadius.only(
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ]
          ),
          child: Text(
            message.content ?? '',
            style: textStyleSmall.copyWith(color: textColor, height: 1.4),
          ),
        ),
        Padding(
          padding: isMe
              ? const EdgeInsets.only(right: 10.0, bottom: 6.0)
              : const EdgeInsets.only(left: 10.0, bottom: 6.0),
          child: Text(
            DateFormat('HH:mm').format(message.dateTime.toLocal()), // 시간을 HH:mm 형식으로 표시
            style: textStyleSmall.copyWith(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInputField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea( // 키보드 위 UI가 시스템 영역 침범하지 않도록
        child: Row(
          children: [
            // TODO: 파일 첨부 등 추가 버튼 영역
            // IconButton(
            //   icon: Icon(Icons.add_photo_alternate_outlined, color: Colors.grey.shade600),
            //   onPressed: () {
            //     // 파일 첨부 로직
            //   },
            // ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.0), // TextField 내부 패딩 조절
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor, // TextField 배경색
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TextField(
                  controller: controller.messageInputController,
                  style: textStyleSmall,
                  decoration: InputDecoration(
                    hintText: "메시지를 입력하세요...",
                    hintStyle: textStyleSmall.copyWith(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // 내부 content padding
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  onSubmitted: (value) => controller.sendMessage(),
                ),
              ),
            ),
            horizontalSpaceSmall,
            Material( // IconButton에 Ink 효과를 주기 위해 Material 위젯으로 감쌈
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: controller.sendMessage,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.send_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}