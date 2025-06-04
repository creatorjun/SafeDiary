import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../services/chat_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatService>(() => ChatService());

    // ChatController는 partnerUid와 partnerNickname을 인자로 받으므로,
    // Get.arguments를 통해 라우팅 시 전달된 값을 가져와 주입합니다.
    final arguments = Get.arguments as Map<String, dynamic>?;
    final String? partnerUid = arguments?['partnerUid'] as String?;
    final String? partnerNickname = arguments?['partnerNickname'] as String?;

    // partnerUid는 필수 값이므로, null 체크 후 예외를 발생시키거나 기본값을 설정할 수 있습니다.
    // ChatController 생성자에서 required로 지정했으므로, 여기서 반드시 제공되어야 합니다.
    if (partnerUid == null) {
      // 이 경우, 라우팅 시 arguments로 partnerUid가 제대로 전달되지 않은 것입니다.
      // Get.offNamed(Routes.HOME); // 예시: 홈으로 돌려보내기
      throw Exception(
          "ChatBinding: partnerUid is null. It must be provided via Get.arguments when navigating to the chat screen.");
    }

    // ChatController를 GetX에 등록합니다.
    // ChatScreen에서는 Get.find<ChatController>()를 통해 이 인스턴스를 사용하게 됩니다.
    // 페이지가 활성화될 때 생성되고, 페이지에서 벗어나면 메모리에서 제거되도록 lazyPut을 사용합니다.
    Get.lazyPut<ChatController>(
          () => ChatController(
        partnerUid: partnerUid,
        partnerNickname: partnerNickname,
      ),
      // fenix: true // 채팅 화면 특성상 뒤로 갔다가 다시 돌아올 때 상태 유지를 원하면 true
      // 하지만 STOMP 연결 등 재연결 로직이 onInit에 있으므로, false(기본값)가 나을 수 있음
    );
  }
}