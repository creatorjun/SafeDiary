import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../services/event_service.dart';
import '../services/weather_service.dart';
import '../controllers/weather_controller.dart';
import '../services/luck_service.dart'; // LuckService 임포트
import '../controllers/luck_controller.dart'; // LuckController 임포트

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventService>(() => EventService());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<WeatherService>(() => WeatherService());
    Get.lazyPut<WeatherController>(() => WeatherController());
    Get.lazyPut<LuckService>(() => LuckService());
    Get.lazyPut<LuckController>(() => LuckController());
  }
}