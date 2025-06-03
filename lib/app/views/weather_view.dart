import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/weather_controller.dart';
import '../models/weather_models.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class WeatherView extends GetView<WeatherController> {
  const WeatherView({super.key});

  String _getBackgroundImagePath(WeatherForecastResponseDto dailyForecast) {
    String weatherDescriptionAm = dailyForecast.weatherAm?.toLowerCase() ?? "";
    String weatherDescriptionPm = dailyForecast.weatherPm?.toLowerCase() ?? "";
    int minTemp = dailyForecast.minTemp ?? 10;
    int rainProbAm = dailyForecast.rainProbAm ?? 0;
    int rainProbPm = dailyForecast.rainProbPm ?? 0;

    if (weatherDescriptionAm.contains("소나기") || weatherDescriptionPm.contains("소나기")) {
      return 'assets/weather/weather7.png';
    }
    if (minTemp <= 5 && (rainProbAm >= 50 || rainProbPm >= 50)) {
      return 'assets/weather/weather6.png';
    }
    if (minTemp > 5 && (rainProbAm >= 50 || rainProbPm >= 50)) {
      return 'assets/weather/weather5.png';
    }
    String primaryWeather = weatherDescriptionAm;
    if (weatherDescriptionPm.contains("흐림")) {
      primaryWeather = weatherDescriptionPm;
    } else if (weatherDescriptionPm.contains("구름") && !primaryWeather.contains("흐림")) {
      primaryWeather = weatherDescriptionPm;
    } else if (weatherDescriptionPm.contains("맑음") && !primaryWeather.contains("흐림") && !primaryWeather.contains("구름")) {
      primaryWeather = weatherDescriptionPm;
    }

    if (primaryWeather.contains("흐림")) {
      return 'assets/weather/weather3.png';
    }
    if (primaryWeather.contains("구름")) {
      return 'assets/weather/weather2.png';
    }
    if (primaryWeather.contains("맑음")) {
      return 'assets/weather/weather1.png';
    }
    return 'assets/weather/weather1.png';
  }

  void _showCitySelectionBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor, // 현재 테마의 배경색 사용
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: SafeArea( // 하단 시스템 영역 침범 방지
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "도시 선택",
                  style: textStyleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              LimitedBox( // ListView의 최대 높이 제한
                maxHeight: MediaQuery.of(context).size.height * 0.5, // 화면 높이의 50%로 제한
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.availableCities.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String city = controller.availableCities[index];
                    bool isSelected = city == controller.selectedCityName.value;
                    return ListTile(
                      title: Text(
                        city,
                        style: textStyleSmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          // color: isSelected ? Theme.of(context).primaryColor : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_outline_rounded, color: Theme.of(context).primaryColor, size: 22)
                          : null,
                      onTap: () {
                        controller.changeCity(city);
                        // Get.back(); // controller.changeCity에서 Get.back() 호출됨
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    );
                  },
                ),
              ),
              // 취소 버튼 대신 외부 탭으로 닫기 유도 또는 상단 X 버튼 추가 가능
              // 여기서는 기본 BottomSheet 동작(외부 탭 시 닫힘)을 활용
            ],
          ),
        ),
      ),
      isScrollControlled: true, // true로 설정해야 내용이 많을 때 전체 화면 스크롤 가능
      // backgroundColor: Colors.transparent, // Container에서 배경색을 관리하므로 투명하게
    );
  }

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.weeklyForecast.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.weeklyForecast.value == null) {
          return _buildErrorView(context);
        }

        final forecastData = controller.weeklyForecast.value;
        if (forecastData == null || forecastData.forecasts.isEmpty) {
          return _buildEmptyView(context);
        }

        return PageView.builder(
          controller: pageController,
          itemCount: forecastData.forecasts.length,
          itemBuilder: (context, index) {
            final dailyForecast = forecastData.forecasts[index];
            final String backgroundImagePath = _getBackgroundImagePath(dailyForecast);
            return _buildDailyForecastPage(context, dailyForecast, controller.selectedCityName.value, backgroundImagePath);
          },
        );
      }),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 48),
            verticalSpaceMedium,
            Text(
              "날씨 정보를 불러오는 데 실패했습니다.",
              style: textStyleMedium.copyWith(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            verticalSpaceSmall,
            Text(
              controller.errorMessage.value,
              style: textStyleSmall.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            verticalSpaceMedium,
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("다시 시도"),
              onPressed: () {
                controller.fetchWeeklyForecast(controller.selectedCityName.value);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: Colors.grey, size: 48),
          verticalSpaceMedium,
          const Text("날씨 정보가 없습니다.", style: textStyleMedium),
          verticalSpaceSmall,
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("새로고침"),
            onPressed: () {
              controller.fetchWeeklyForecast(controller.selectedCityName.value);
            },
          )
        ],
      ),
    );
  }

  Widget _buildDailyForecastPage(BuildContext context,
      WeatherForecastResponseDto dailyForecast, String currentCityName, String backgroundImagePath) {
    DateTime parsedDate;
    String displayDate = "날짜 정보 없음";
    String dayOfWeek = "";

    try {
      parsedDate = DateTime.parse(dailyForecast.date);
      displayDate = DateFormat('MM월 dd일').format(parsedDate);
      dayOfWeek = DateFormat('E', 'ko_KR').format(parsedDate);
    } catch (e) {
      // 날짜 파싱 실패 시 기본값 사용
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundImagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Container(
              color: Colors.blueGrey,
              alignment: Alignment.center,
              child: const Text(
                '배경 이미지 로드 실패',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showCitySelectionBottomSheet(context); // BottomSheet 호출로 변경
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentCityName,
                            style: textStyleLarge.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          horizontalSpaceSmall,
                          const Icon(Icons.edit_location_alt_outlined, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                    verticalSpaceSmall,
                    Text(
                      '$displayDate ($dayOfWeek)',
                      style: textStyleMedium.copyWith(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTempInfo("최저", dailyForecast.minTemp, Colors.lightBlueAccent),
                          _buildTempInfo("최고", dailyForecast.maxTemp, Colors.orangeAccent),
                        ],
                      ),
                      verticalSpaceLarge,
                      if (dailyForecast.weatherAm != null || dailyForecast.weatherPm != null)
                        const Divider(color: Colors.white54),
                      verticalSpaceSmall,
                      _buildWeatherDetailRow("오전 날씨", dailyForecast.weatherAm),
                      _buildWeatherDetailRow("오전 강수확률", dailyForecast.rainProbAm?.toString(), unit: "%"),
                      verticalSpaceMedium,
                      _buildWeatherDetailRow("오후 날씨", dailyForecast.weatherPm),
                      _buildWeatherDetailRow("오후 강수확률", dailyForecast.rainProbPm?.toString(), unit: "%"),
                      verticalSpaceLarge,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios, color: Colors.white70, size: 16),
                          horizontalSpaceSmall,
                          Text("스와이프하여 날짜 변경", style: textStyleSmall.copyWith(color: Colors.white70)),
                          horizontalSpaceSmall,
                          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 5,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            tooltip: "새로고침",
            onPressed: () => controller.fetchWeeklyForecast(controller.selectedCityName.value),
          ),
        ),
      ],
    );
  }

  Widget _buildTempInfo(String label, int? temp, Color color) {
    return Column(
      children: [
        Text(label, style: textStyleSmall.copyWith(color: Colors.white70)),
        verticalSpaceSmall,
        Text(
          temp != null ? '$temp°' : '-',
          style: textStyleLarge.copyWith(fontSize: 48, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailRow(String label, String? value, {String unit = ""}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyleMedium.copyWith(color: Colors.white.withOpacity(0.85))),
          Text(
            value != null ? '$value$unit' : '-',
            style: textStyleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}