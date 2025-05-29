// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:safe_diary/app/routes/app_pages.dart';
import 'package:safe_diary/main.dart';
import 'package:safe_diary/app/bindings/login_binding.dart';
import 'package:safe_diary/app/controllers/login_controller.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // LoginBinding을 통해 LoginController를 GetX에 영구적으로 등록
    if (!Get.isRegistered<LoginController>()) {
      LoginBinding().dependencies();
    }
    final LoginController loginController = Get.find<LoginController>();

    // 자동 로그인 시도
    bool autoLoginSuccess = false;
    try {
      autoLoginSuccess = await loginController.tryAutoLoginWithRefreshToken();
    } catch (e) {
      if (kDebugMode) {
        print("[main.dart] Auto login attempt failed: $e");
      }
      autoLoginSuccess = false;
    }
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(initialRoute: autoLoginSuccess ? Routes.HOME : Routes.LOGIN),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
