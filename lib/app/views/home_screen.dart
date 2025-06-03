// lib/app/views/home_screen.dart

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../controllers/home_controller.dart';
import '../controllers/login_controller.dart';
import '../routes/app_pages.dart';
import './calendar_view.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();

    final List<Widget> screens = [
      const CalendarView(),
      const Center(
        child: Placeholder(child: Text("날씨 화면", style: textStyleMedium)),
      ),
      const Center(
        child: Placeholder(child: Text("운세 화면", style: textStyleMedium)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final displayTitle =
              '${loginController.user.nickname ?? '사용자'}님 - ${controller.currentTitle}';
          return Text(
            displayTitle,
            style: textStyleLarge, //
            overflow: TextOverflow.ellipsis,
          );
        }),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.redAccent,
                Colors.purpleAccent,
                Colors.greenAccent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: '더보기',
            onSelected: (String value) {
              print('[HomeScreen] PopupMenu onSelected: $value'); // 선택된 값 로그 출력
              if (value == 'profile') {
                Get.toNamed(Routes.PROFILE_AUTH);
              } else if (value == 'logout') {
                print(
                  '[HomeScreen] 로그아웃 메뉴 선택됨, loginController.logout() 호출 시도',
                );
                loginController.logout(); // 이 부분이 실행되는지 확인
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.black87),
                        horizontalSpaceSmall, //
                        const Text('개인정보', style: textStyleSmall), //
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.black87),
                        horizontalSpaceSmall, //
                        const Text('로그아웃', style: textStyleSmall), //
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
        () => WaterDropNavBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          waterDropColor: Colors.purpleAccent,
          inactiveIconColor: Colors.grey,
          iconSize: 28,
          bottomPadding: 10,
          barItems: [
            BarItem(
              filledIcon: Icons.calendar_month,
              outlinedIcon: Icons.calendar_month_outlined,
            ),
            BarItem(
              filledIcon: Icons.wb_sunny,
              outlinedIcon: Icons.wb_sunny_outlined,
            ),
            BarItem(
              filledIcon: Icons.explore,
              outlinedIcon: Icons.explore_outlined,
            ),
          ],
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: (index) {
            controller.changeTabIndex(index);
          },
        ),
      ),
      floatingActionButton: Obx(() {
        if (controller.selectedIndex.value == 0) {
          return FloatingActionButton.small(
            onPressed: () {
              controller.showAddEventDialog();
            },
            tooltip: '일정 추가',
            backgroundColor: Colors.purpleAccent,
            child: const Icon(Icons.add),
          );
        } else {
          return const SizedBox.shrink();
        }
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
