// lib/app/views/widgets/add_edit_event_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/event_item.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class AddEditEventDialog extends StatefulWidget {
  final DateTime eventDate;
  final EventItem? existingEvent; // 수정 모드일 경우 기존 이벤트 데이터
  final Function(EventItem event) onSubmit;

  const AddEditEventDialog({
    super.key,
    required this.eventDate,
    this.existingEvent,
    required this.onSubmit,
  });

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  late TextEditingController _titleController;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingEvent?.title ?? '');
    _startTime = widget.existingEvent?.startTime;
    _endTime = widget.existingEvent?.endTime;

    if (widget.existingEvent == null) { // 새 이벤트 추가 시 기본 시간 설정
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime = (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _clearTime(bool isStartTime) {
    setState(() {
      if (isStartTime) {
        _startTime = null;
      } else {
        _endTime = null;
      }
    });
  }

  Widget _buildTimePickerRow(String label, TimeOfDay? currentTime, bool isStartTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$label: ${currentTime?.format(context) ?? "미지정"}',
            style: textStyleSmall,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentTime != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                tooltip: '시간 지우기',
                onPressed: () => _clearTime(isStartTime),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            horizontalSpaceSmall,
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: textStyleSmall.copyWith(fontSize: 13),
              ),
              onPressed: () => _selectTime(context, isStartTime),
              child: const Text("시간 선택"),
            ),
          ],
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_startTime != null && _endTime != null) {
        final startTimeDouble = _startTime!.hour + _startTime!.minute / 60.0;
        final endTimeDouble = _endTime!.hour + _endTime!.minute / 60.0;
        if (endTimeDouble <= startTimeDouble) {
          Get.snackbar("오류", "종료 시간은 시작 시간보다 늦어야 합니다.");
          return;
        }
      }

      final event = EventItem(
        backendEventId: widget.existingEvent?.backendEventId,
        title: _titleController.text.trim(),
        eventDate: widget.eventDate, // dialog 생성 시 전달받은 날짜
        startTime: _startTime,
        endTime: _endTime,
        createdAt: widget.existingEvent?.createdAt,
      );
      widget.onSubmit(event);
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingEvent != null;
    final String dialogTitle = isEditing ? "일정 수정" : "일정 추가";
    final String submitButtonText = isEditing ? "수정" : "추가";

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      title: Text(
        "${DateFormat('MM월 dd일', 'ko_KR').format(widget.eventDate.toLocal())} $dialogTitle",
        style: textStyleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: "일정 내용을 입력하세요",
                    isDense: true,
                  ),
                  style: textStyleMedium,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '일정 내용을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                verticalSpaceMedium,
                _buildTimePickerRow("시작", _startTime, true),
                verticalSpaceSmall,
                _buildTimePickerRow("종료", _endTime, false),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(onPressed: () => Get.back(), child: const Text("취소")),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _handleSubmit,
            child: Text(submitButtonText),
          ),
        ),
      ],
    );
  }
}