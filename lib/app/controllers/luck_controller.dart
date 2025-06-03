import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/luck_models.dart';
import '../services/luck_service.dart';
import '../services/secure_storage_service.dart';
import 'login_controller.dart';

class LuckController extends GetxController {
  final LuckService _luckService = Get.find<LuckService>();
  final LoginController _loginController = Get.find<LoginController>();
  final SecureStorageService _secureStorageService = Get.find<SecureStorageService>();

  final Rx<ZodiacLuckData?> zodiacLuck = Rx<ZodiacLuckData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _defaultZodiacApiName = "쥐띠"; // API 요청 시 기본값
  final RxString selectedZodiacApiName = _defaultZodiacApiName.obs; // API 요청용 띠 이름

  // UI 표시용 띠 이름과 API 요청용 띠 이름 매핑
  final Map<String, String> zodiacNameMap = {
    "자(쥐)": "쥐띠",
    "축(소)": "소띠",
    "인(호랑이)": "호랑이띠",
    "묘(토끼)": "토끼띠",
    "진(용)": "용띠",
    "사(뱀)": "뱀띠",
    "오(말)": "말띠",
    "미(양)": "양띠",
    "신(원숭이)": "원숭이띠",
    "유(닭)": "닭띠",
    "술(개)": "개띠",
    "해(돼지)": "돼지띠",
  };

  // UI 선택용 띠 목록 (Map의 key들)
  List<String> get availableZodiacsForDisplay => zodiacNameMap.keys.toList();

  // 현재 선택된 띠의 UI 표시용 이름
  String get currentSelectedZodiacDisplayName {
    // selectedZodiacApiName에 해당하는 display 이름을 찾음
    return zodiacNameMap.entries
        .firstWhere((entry) => entry.value == selectedZodiacApiName.value,
        orElse: () => MapEntry(availableZodiacsForDisplay.first, _defaultZodiacApiName) // 못찾으면 기본값의 표시 이름
    )
        .key;
  }


  @override
  void onInit() {
    super.onInit();
    _loadSavedZodiacAndFetchLuck();

    ever(_loginController.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        fetchTodaysLuck(selectedZodiacApiName.value);
      } else {
        zodiacLuck.value = null;
        errorMessage.value = '';
      }
    });
  }

  Future<void> _loadSavedZodiacAndFetchLuck() async {
    String? savedZodiacApiName = await _secureStorageService.getSelectedZodiac();
    // 저장된 값이 zodiacNameMap의 value (API용 이름) 중에 있는지 확인
    if (savedZodiacApiName != null && zodiacNameMap.containsValue(savedZodiacApiName)) {
      selectedZodiacApiName.value = savedZodiacApiName;
    } else {
      selectedZodiacApiName.value = _defaultZodiacApiName; // 유효하지 않으면 기본값
    }

    if (_loginController.isLoggedIn.value) {
      fetchTodaysLuck(selectedZodiacApiName.value);
    }
  }

  Future<void> fetchTodaysLuck(String zodiacApiName) async {
    // API 요청 시에는 항상 API용 이름 (예: "쥐띠")을 사용
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final luckData = await _luckService.getTodaysLuck(zodiacApiName);
      zodiacLuck.value = luckData;
      if (kDebugMode) {
        print('[LuckController] Fetched today\'s luck for $zodiacApiName: ${luckData.overallLuck}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (kDebugMode) {
        print('[LuckController] Error fetching luck for $zodiacApiName: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // 이 메서드는 UI에서 표시용 이름(예: "자(쥐)")을 받았을 때 호출됨
  Future<void> changeZodiacByDisplayName(String zodiacDisplayName) async {
    String? newApiName = zodiacNameMap[zodiacDisplayName]; // 표시용 이름으로 API용 이름을 찾음

    if (newApiName != null && selectedZodiacApiName.value != newApiName) {
      selectedZodiacApiName.value = newApiName;
      await _secureStorageService.saveSelectedZodiac(newApiName);
      fetchTodaysLuck(newApiName);
      Get.back(); // 띠 선택 다이얼로그 닫기
    } else if (newApiName != null && selectedZodiacApiName.value == newApiName) {
      Get.back(); // 이미 선택된 띠이므로 다이얼로그만 닫음
    } else {
      if (kDebugMode) {
        print('[LuckController] Attempted to change to an unavailable zodiac display name: $zodiacDisplayName');
      }
    }
  }
}