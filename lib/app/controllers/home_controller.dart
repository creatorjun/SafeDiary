// lib/app/controllers/home_controller.dart

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event_item.dart';
import '../controllers/login_controller.dart';
import '../routes/app_pages.dart';
import '../services/event_service.dart';
import '../views/widgets/add_edit_event_dialog.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';


class HomeController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final List<String> tabTitles = ['일정', '날씨', '운세'];

  String get currentTitle => tabTitles[selectedIndex.value];

  late final LoginController _loginController;
  final RxBool _newUserWarningShown = false.obs;

  late final EventService _eventService;

  final RxBool isLoadingEvents = false.obs;
  final RxBool isSubmittingEvent = false.obs;

  late final Rx<DateTime> focusedDay;
  late final Rx<DateTime?> selectedDay;

  final RxMap<DateTime, List<EventItem>> events =
  RxMap<DateTime, List<EventItem>>(
    LinkedHashMap<DateTime, List<EventItem>>(
      equals: isSameDay,
      hashCode: (key) =>
      key.year * 1000000 + key.month * 10000 + key.day,
    ),
  );

  List<EventItem> get selectedDayEvents {
    final day = selectedDay.value;
    if (day == null) return <EventItem>[];
    final eventsForDay = events[day] ?? <EventItem>[];
    eventsForDay.sort((a, b) {
      final aStart = a.startTime;
      final bStart = b.startTime;

      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;

      double timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;
      return timeToDouble(aStart).compareTo(timeToDouble(bStart));
    });
    return eventsForDay;
  }

  // _normalizeDate 메서드 정의
  DateTime _normalizeDate(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }

  @override
  void onInit() {
    super.onInit();
    _loginController = Get.find<LoginController>();
    _eventService = Get.find<EventService>();

    final now = DateTime.now();
    final normalizedNow = _normalizeDate(now); // 여기서 _normalizeDate 사용
    focusedDay = normalizedNow.obs;
    selectedDay = normalizedNow.obs;

    _loadEventsFromServer();
  }

  @override
  void onReady() {
    super.onReady();
    _checkAndShowNewUserWarning();
  }

  void _checkAndShowNewUserWarning() {
    if (_loginController.user.isNew &&
        !_loginController.user.isAppPasswordSet &&
        !_newUserWarningShown.value) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isRegistered<HomeController>() && Get.context != null) {
          _showNewUserPasswordSetupWarning();
          _newUserWarningShown.value = true;
        }
      });
    }
  }

  void _showNewUserPasswordSetupWarning() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: Wrap(
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🔒 개인 정보 보호 알림',
                  style: textStyleLarge,
                  textAlign: TextAlign.center,
                ),
                verticalSpaceMedium,
                Text(
                  "개인정보 - 비밀번호 설정을 활성화 해주세요.",
                  style: textStyleMedium.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                verticalSpaceLarge,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text('나중에 하기', style: textStyleSmall),
                      ),
                    ),
                    horizontalSpaceSmall,
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor:
                          Theme.of(Get.context!,).primaryColor,
                        ),
                        onPressed: () {
                          Get.back();
                          Get.toNamed(Routes.PROFILE_AUTH);
                        },
                        child: Text(
                          '지금 설정',
                          style: textStyleSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }

  void onDaySelected(DateTime newSelectedDay, DateTime newFocusedDay) {
    final normalizedNewSelectedDay = _normalizeDate(newSelectedDay); // 여기서 _normalizeDate 사용
    if (selectedDay.value == null || !isSameDay(selectedDay.value!, normalizedNewSelectedDay)) {
      selectedDay.value = normalizedNewSelectedDay;
    }
    focusedDay.value = _normalizeDate(newFocusedDay); // 여기서 _normalizeDate 사용
  }

  void onPageChanged(DateTime newFocusedDay) {
    focusedDay.value = _normalizeDate(newFocusedDay); // 여기서 _normalizeDate 사용
  }

  List<EventItem> getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day); // 여기서 _normalizeDate 사용
    final eventsForDay = events[normalizedDay] ?? <EventItem>[];
    eventsForDay.sort((a, b) {
      final aStart = a.startTime;
      final bStart = b.startTime;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      double timeToDouble(TimeOfDay time) => time.hour + time.minute / 60.0;
      return timeToDouble(aStart).compareTo(timeToDouble(bStart));
    });
    return eventsForDay;
  }

  Future<void> _loadEventsFromServer() async {
    isLoadingEvents.value = true;
    try {
      final List<EventItem> serverEvents = await _eventService.getEvents();
      final newEventsMap = LinkedHashMap<DateTime, List<EventItem>>(
        equals: isSameDay,
        hashCode: (key) => key.year * 1000000 + key.month * 10000 + key.day,
      );

      for (var event in serverEvents) {
        final normalizedEventDate = _normalizeDate(event.eventDate); // 여기서 _normalizeDate 사용
        final list = newEventsMap.putIfAbsent(normalizedEventDate, () => []);
        list.add(event);
      }
      events.clear();
      events.addAll(newEventsMap);
      events.refresh();
    } catch (e) {
      // Get.snackbar('오류', '이벤트 목록을 불러오는 데 실패했습니다: ${e.toString()}');
    } finally {
      isLoadingEvents.value = false;
    }
  }

  void showAddEventDialog() {
    if (selectedDay.value == null) {
      Get.snackbar("알림", "먼저 날짜를 선택해주세요.");
      return;
    }
    Get.dialog(
      AddEditEventDialog(
        eventDate: selectedDay.value!,
        onSubmit: (event) {
          _createEventOnServer(event);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _createEventOnServer(EventItem event) async {
    isSubmittingEvent.value = true;
    try {
      final createdEvent = await _eventService.createEvent(event);
      final normalizedEventDate = _normalizeDate(createdEvent.eventDate); // 여기서 _normalizeDate 사용

      final list = events.putIfAbsent(normalizedEventDate, () => []);
      list.add(createdEvent);
      events.refresh();
      // Get.snackbar("성공", "새로운 일정이 추가되었습니다.");
    } catch (e) {
      // Get.snackbar("오류", "일정 추가 실패: ${e.toString()}");
    } finally {
      isSubmittingEvent.value = false;
    }
  }

  void showEditEventDialog(EventItem existingEvent) {
    Get.dialog(
      AddEditEventDialog(
        eventDate: existingEvent.eventDate,
        existingEvent: existingEvent,
        onSubmit: (event) {
          _updateEventOnServer(event);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _updateEventOnServer(EventItem eventToUpdate) async {
    if (eventToUpdate.backendEventId == null) {
      // Get.snackbar("오류", "수정할 이벤트 ID가 없습니다.");
      return;
    }
    isSubmittingEvent.value = true;
    try {
      final updatedEventFromServer = await _eventService.updateEvent(eventToUpdate);

      final originalNormalizedDate = _normalizeDate(eventToUpdate.eventDate); // 여기서 _normalizeDate 사용
      if (events[originalNormalizedDate] != null) {
        events[originalNormalizedDate]!.removeWhere((e) => e.backendEventId == updatedEventFromServer.backendEventId);
        if (events[originalNormalizedDate]!.isEmpty) {
        }
      }

      final updatedNormalizedDate = _normalizeDate(updatedEventFromServer.eventDate); // 여기서 _normalizeDate 사용
      final list = events.putIfAbsent(updatedNormalizedDate, () => []);
      list.add(updatedEventFromServer);

      events.refresh();
      // Get.snackbar("성공", "일정이 수정되었습니다.");
    } catch (e) {
      // Get.snackbar("오류", "일정 수정 실패: ${e.toString()}");
    } finally {
      isSubmittingEvent.value = false;
    }
  }

  void confirmDeleteEvent(EventItem eventToDelete) {
    if (eventToDelete.backendEventId == null) {
      // Get.snackbar("오류", "삭제할 이벤트 ID가 없습니다.");
      return;
    }
    Get.dialog(
      AlertDialog(
        title: const Text("일정 삭제"),
        content: Text("'${eventToDelete.title}' 일정을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("취소")),
          TextButton(
            onPressed: () {
              Get.back();
              _deleteEventOnServer(eventToDelete);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEventOnServer(EventItem eventToDelete) async {
    if (eventToDelete.backendEventId == null) return;

    isSubmittingEvent.value = true;
    try {
      await _eventService.deleteEvent(eventToDelete.backendEventId!);

      final normalizedEventDate = _normalizeDate(eventToDelete.eventDate); // 여기서 _normalizeDate 사용
      if (events[normalizedEventDate] != null) {
        events[normalizedEventDate]!.removeWhere((e) => e.backendEventId == eventToDelete.backendEventId);
        if (events[normalizedEventDate]!.isEmpty) {
        }
        events.refresh();
        // Get.snackbar("성공", "일정이 삭제되었습니다.");
      }
    } catch (e) {
      // Get.snackbar("오류", "일정 삭제 실패: ${e.toString()}");
    } finally {
      isSubmittingEvent.value = false;
    }
  }

  void changeTabIndex(int index) {
    if (index >= 0 && index < tabTitles.length) {
      selectedIndex.value = index;
    }
  }
}