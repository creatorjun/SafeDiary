// lib/app/bindings/home_binding.dart

import 'package:get/get.dart';
import '../controllers/home_controller.dart'; // HomeController 임포트
import '../services/event_service.dart'; // EventService 임포트

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // EventService를 먼저 등록합니다. (HomeController가 의존하므로)
    // lazyPut을 사용하면 EventService가 처음 필요할 때 인스턴스화됩니다.
    Get.lazyPut<EventService>(() => EventService());

    // HomeController를 GetX에 lazyPut 방식으로 등록합니다.
    // HomeController가 처음 사용될 때 인스턴스가 생성됩니다.
    Get.lazyPut<HomeController>(() => HomeController());
  }
}