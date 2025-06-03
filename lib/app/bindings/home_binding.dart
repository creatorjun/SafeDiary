import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../services/event_service.dart';
import '../services/weather_service.dart'; // WeatherService 임포트
import '../controllers/weather_controller.dart'; // WeatherController 임포트

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventService>(() => EventService());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<WeatherService>(() => WeatherService());
    Get.lazyPut<WeatherController>(() => WeatherController());
  }
}