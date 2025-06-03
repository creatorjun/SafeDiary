import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../services/secure_storage_service.dart'; // SecureStorageService 임포트
import 'login_controller.dart';

class WeatherController extends GetxController {
  final WeatherService _weatherService = Get.find<WeatherService>();
  final LoginController _loginController = Get.find<LoginController>();
  final SecureStorageService _secureStorageService = Get.find<SecureStorageService>(); // SecureStorageService 주입

  final Rx<WeeklyForecastResponseDto?> weeklyForecast = Rx<WeeklyForecastResponseDto?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _defaultCityName = "서울";
  final RxString selectedCityName = _defaultCityName.obs;

  final List<String> availableCities = [
    "서울", "부산", "대구", "인천", "광주", "대전", "울산",
    "수원", "춘천", "강릉", "청주", "전주", "포항", "제주"
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedCityAndFetchWeather();

    ever(_loginController.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        // 로그인 상태가 되면 현재 선택된 도시(저장된 값 또는 기본값)로 날씨 정보 다시 요청
        fetchWeeklyForecast(selectedCityName.value);
      } else {
        weeklyForecast.value = null;
        errorMessage.value = '';
        // 로그아웃 시 선택된 도시를 기본값으로 되돌릴 수도 있습니다. (선택적)
        // selectedCityName.value = _defaultCityName;
        // await _secureStorageService.clearSelectedCity();
      }
    });
  }

  Future<void> _loadSavedCityAndFetchWeather() async {
    String? savedCity = await _secureStorageService.getSelectedCity();
    selectedCityName.value = savedCity ?? _defaultCityName;

    // 로그인 상태라면 바로 날씨 정보 가져오기
    if (_loginController.isLoggedIn.value) {
      fetchWeeklyForecast(selectedCityName.value);
    }
  }

  Future<void> fetchWeeklyForecast(String cityName, [String? date]) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final forecastData =
      await _weatherService.getWeeklyForecastByCityName(cityName, date);
      weeklyForecast.value = forecastData;
      // API 응답의 regionName이 실제 도시 이름과 다를 수 있으므로,
      // selectedCityName은 사용자가 선택한 값을 유지하거나, API 응답의 regionName으로 업데이트 할지 결정 필요.
      // 여기서는 사용자가 선택한 selectedCityName을 유지합니다.
      // 만약 API 응답의 regionName을 사용하고 싶다면, 아래 주석 해제
      // if (forecastData.regionName != null && forecastData.regionName!.isNotEmpty) {
      //   selectedCityName.value = forecastData.regionName!;
      // }

      if (kDebugMode) {
        if (forecastData.forecasts.isNotEmpty) {
          print(
              '[WeatherController] Fetched weather for ${forecastData.regionName ?? cityName}, first day: ${forecastData.forecasts.first.date}');
        } else {
          print(
              '[WeatherController] Fetched weather for ${forecastData.regionName ?? cityName}, but no forecast data available.');
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        print('[WeatherController] Error fetching weekly forecast for $cityName: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeCity(String newCityName) async {
    if (availableCities.contains(newCityName) && selectedCityName.value != newCityName) {
      selectedCityName.value = newCityName;
      await _secureStorageService.saveSelectedCity(newCityName);
      fetchWeeklyForecast(newCityName); // 새 도시로 날씨 정보 업데이트
      Get.back(); // 도시 선택 다이얼로그 닫기
    } else if (selectedCityName.value == newCityName) {
      Get.back(); // 이미 선택된 도시이므로 다이얼로그만 닫음
    } else {
      if (kDebugMode) {
        print('[WeatherController] Attempted to change to an unavailable city: $newCityName');
      }
      // 사용자에게 알림 (선택 사항)
      Get.snackbar("오류", "선택할 수 없는 도시입니다.");
    }
  }
}