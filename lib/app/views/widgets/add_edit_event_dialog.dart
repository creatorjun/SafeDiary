// lib/app/views/widgets/add_edit_event_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/event_item.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
// import 'package:flutter/foundation.dart'; // kDebugMode 사용 시

class AddEditEventDialog extends StatefulWidget {
  final DateTime eventDate;
  final EventItem? existingEvent;
  final Function(EventItem event) onSubmit; // 원래 Function 타입 유지

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
  bool _isSubmitting = false; // 중복 제출 방지용

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingEvent?.title ?? '');
    _startTime = widget.existingEvent?.startTime;
    _endTime = widget.existingEvent?.endTime;

    if (widget.existingEvent == null) {
      _startTime = TimeOfDay.now();
      _endTime =
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final initialTime =
        (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) { // 타임피커 테마 적용 (선택 사항)
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              // 필요에 따라 다른 속성들도 커스터마이징
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary, // 버튼 텍스트 색상
              ),
            ),
          ),
          child: child!,
        );
      },
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

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay? currentTime,
    required bool isStartTime,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
      title: Text(label, style: textStyleSmall),
      subtitle: Text(
        currentTime?.format(context) ?? "시간 미지정",
        style: textStyleMedium.copyWith(
            color: currentTime == null
                ? Colors.grey.shade600
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500),
      ),
      trailing: currentTime != null
          ? IconButton(
        icon: Icon(Icons.clear_rounded,
            size: 20, color: Colors.grey.shade500),
        tooltip: '시간 지우기',
        onPressed: () => _clearTime(isStartTime),
      )
          : null,
      onTap: () => _selectTime(context, isStartTime),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
      dense: true,
    );
  }

  void _handleSubmit() {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      if (_startTime != null && _endTime != null) {
        final startTimeDouble = _startTime!.hour + _startTime!.minute / 60.0;
        final endTimeDouble = _endTime!.hour + _endTime!.minute / 60.0;
        if (endTimeDouble <= startTimeDouble) {
          // Get.snackbar 호출은 이전 버전의 HomeController와 상호작용할 때 문제가 될 수 있으므로
          // 이 부분은 그대로 두거나, 더 나은 UX를 위해 에러 표시 방식을 고민해볼 수 있습니다.
          // 여기서는 Get.snackbar를 그대로 사용합니다 (HomeController 롤백 버전에 맞춰서).
          Get.snackbar("오류", "종료 시간은 시작 시간보다 늦어야 합니다.",
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(12),
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white);
          return;
        }
      }
      setState(() { _isSubmitting = true; });

      final event = EventItem(
        backendEventId: widget.existingEvent?.backendEventId,
        title: _titleController.text.trim(),
        eventDate: widget.eventDate,
        startTime: _startTime,
        endTime: _endTime,
        createdAt: widget.existingEvent?.createdAt,
      );

      widget.onSubmit(event);
      // setState(() { _isSubmitting = false; }); // onSubmit이 동기면 여기서, 비동기면 콜백 후
      // 현재 onSubmit은 async void이므로, isSubmitting 해제는 HomeController에서 이루어집니다.
      // 하지만 이 다이얼로그가 닫힌 후이므로, _isSubmitting을 여기서 관리하는 것이 안전합니다.
      // Get.back()이 호출되기 전에 false로 설정하거나, Get.back()후에 호출될 콜백이 없으므로
      // _isSubmitting 상태는 다이얼로그가 닫히면 자동으로 해제됩니다.
      // 명시적으로 false로 여기서 바꿔줄 필요는 없습니다.
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingEvent != null;
    final String dialogTitleText = isEditing ? "일정 수정" : "일정 추가";
    final String submitButtonText = isEditing ? "수정" : "추가";
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: primaryColor, size: 22),
          horizontalSpaceSmall,
          Expanded(
            child: Text(
              "${DateFormat('MM월 dd일 (E)', 'ko_KR').format(widget.eventDate.toLocal())} $dialogTitleText",
              style: textStyleMedium.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              verticalSpaceSmall,
              TextFormField(
                controller: _titleController,
                autofocus: true, // 새 일정 추가 시 자동 포커스
                decoration: InputDecoration(
                  labelText: "일정 내용",
                  hintText: "무슨 일정이 있나요?",
                  prefixIcon: Icon(Icons.notes_rounded, color: Colors.grey.shade600, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              _buildTimePickerTile(
                label: "시작 시간",
                currentTime: _startTime,
                isStartTime: true,
                icon: Icons.access_time_outlined,
              ),
              _buildTimePickerTile(
                label: "종료 시간",
                currentTime: _endTime,
                isStartTime: false,
                icon: Icons.timelapse_outlined,
              ),
              verticalSpaceSmall,
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text("취소", style: textStyleSmall.copyWith(color: Colors.grey.shade700)),
          onPressed: () {
            Get.back();
          },
        ),
        FilledButton.icon( // Material 3 스타일 버튼
          icon: _isSubmitting
              ? Container(
              width: 18, height: 18,
              margin: const EdgeInsets.only(right: 4),
              child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary)
          )
              : Icon(isEditing ? Icons.check_circle_outline : Icons.add_circle_outline, size: 18),
          label: Text(submitButtonText, style: textStyleSmall.copyWith(fontWeight: FontWeight.bold)),
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
      ],
    );
  }
}