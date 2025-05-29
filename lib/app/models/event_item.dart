// lib/app/models/event_item.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart'; // For Get.context in displayTime
import 'package:intl/intl.dart'; // DateFormat을 위해 추가

class EventItem {
  final String? backendEventId;
  final String title;
  final DateTime eventDate;
  final TimeOfDay? startTime; // Nullable로 변경
  final TimeOfDay? endTime;   // Nullable로 변경
  final DateTime? createdAt;

  EventItem({
    this.backendEventId,
    required this.title,
    required this.eventDate,
    this.startTime, // Nullable
    this.endTime,   // Nullable
    this.createdAt,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final DateTime parsedEventDate = DateTime.parse(json['eventDate'] as String);
    TimeOfDay? parsedStartTime;
    TimeOfDay? parsedEndTime;

    if (json['startTime'] != null) {
      final List<String> startParts = (json['startTime'] as String).split(':');
      parsedStartTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
    }

    if (json['endTime'] != null) {
      final List<String> endParts = (json['endTime'] as String).split(':');
      parsedEndTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
    }

    return EventItem(
      backendEventId: json['backendEventId'] as String?,
      title: json['text'] as String,
      eventDate: parsedEventDate,
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final String formattedEventDate = dateFormatter.format(eventDate);

    return {
      'text': title,
      'eventDate': formattedEventDate,
      'startTime': startTime != null
          ? '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
          : null, // Nullable 처리
      'endTime': endTime != null
          ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
          : null, // Nullable 처리
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    final Map<String, dynamic> json = toJsonForCreate();
    json['eventId'] = backendEventId;
    return json;
  }

  String _formatTimeOfDay(TimeOfDay? time, BuildContext context) {
    if (time == null) {
      return "미지정";
    }
    return time.format(context);
  }

  String displayTime(BuildContext context) {
    final String start = _formatTimeOfDay(startTime, context);
    final String end = _formatTimeOfDay(endTime, context);

    if (startTime == null && endTime == null) {
      return "시간 미지정"; // 둘 다 미지정이면 간단히 표시
    }
    return '$start - $end';
  }

  EventItem copyWith({
    String? backendEventId,
    String? title,
    DateTime? eventDate,
    ValueGetter<TimeOfDay?>? startTime, // Nullable TimeOfDay를 위한 ValueGetter
    ValueGetter<TimeOfDay?>? endTime,   // Nullable TimeOfDay를 위한 ValueGetter
    DateTime? createdAt,
  }) {
    return EventItem(
      backendEventId: backendEventId ?? this.backendEventId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime != null ? startTime() : this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    // Get.context가 null일 수 있으므로 안전하게 호출
    String startTimeStr = startTime?.format(Get.context!) ?? "미지정";
    String endTimeStr = endTime?.format(Get.context!) ?? "미지정";
    return 'EventItem(backendEventId: $backendEventId, title: $title, eventDate: ${DateFormat('yyyy-MM-dd').format(eventDate)}, startTime: $startTimeStr, endTime: $endTimeStr, createdAt: $createdAt)';
  }
}