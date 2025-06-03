// lib/app/controllers/partner_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/partner_dtos.dart';
import '../models/user.dart'; // User 모델을 직접 참조하기보다 LoginController를 통해 접근
import 'login_controller.dart';

class PartnerController extends GetxController {
  final LoginController _loginController = Get.find<LoginController>();

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final Rx<PartnerInvitationResponseDto?> currentInvitation = Rx<PartnerInvitationResponseDto?>(null);
  final Rx<PartnerRelationResponseDto?> currentPartnerRelation = Rx<PartnerRelationResponseDto?>(null);

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void _setError(String detailedLogMessage, {bool showGeneralMessageToUser = true}) {
    if (kDebugMode) {
      print("[PartnerController] Detailed Error: $detailedLogMessage");
    }
    _errorMessage.value = showGeneralMessageToUser ? "파트너 관련 작업 중 오류가 발생했습니다." : detailedLogMessage;
  }

  @override
  void onInit() {
    super.onInit();
    // LoginController의 user 객체가 변경될 때 (특히 partnerUid) 상태를 동기화
    ever(_loginController.obs, (LoginController loginController) {
      _synchronizePartnerStatus(loginController.user);
    });
    // 컨트롤러 초기화 시점에도 한번 동기화 실행
    _synchronizePartnerStatus(_loginController.user);
  }

  // LoginController의 User 객체를 받아 파트너 상태를 동기화하는 메서드
  void _synchronizePartnerStatus(User user) {
    if (kDebugMode) {
      print("[PartnerController] Synchronizing partner status for user: ${user.id}, partnerUid: ${user.partnerUid}");
    }
    if (user.partnerUid == null || user.partnerUid!.isEmpty) {
      if (currentPartnerRelation.value != null) {
        currentPartnerRelation.value = null;
        if (kDebugMode) print("[PartnerController] Partner relation cleared because user.partnerUid is null or empty.");
      }
      // currentInvitation은 초대 코드 생성 시에만 값이 설정되므로 여기서 건드리지 않거나,
      // 필요하다면 특정 조건(예: 파트너 연결이 막 해제된 경우)에 초기화 할 수 있습니다.
    } else {
      // partnerUid가 있는데 currentPartnerRelation이 null이거나,
      // currentPartnerRelation의 파트너 UID와 user.partnerUid가 다른 경우
      // (예: 다른 계정으로 로그인했으나 이전 계정의 파트너 정보가 남아있는 극단적 케이스 방지)
      if (currentPartnerRelation.value == null || currentPartnerRelation.value!.partnerUser.userUid != user.partnerUid) {
        // 현재 API 스펙상 partnerUid만으로 전체 PartnerRelationResponseDto를 가져올 수 없습니다.
        // 따라서, 초대 수락 시점에 저장된 currentPartnerRelation.value를 유지하거나,
        // partnerUid가 존재한다는 사실만을 기반으로 UI를 업데이트해야 합니다.
        // ProfileScreen에서는 loginController.user.partnerUid를 우선적으로 확인하므로,
        // currentPartnerRelation이 정확한 최신 정보가 아니더라도 UI는 파트너 유무를 판단할 수 있습니다.
        // 만약 currentPartnerRelation을 채우려면, 로그인 시 파트너 상세 정보를 받아오는 API가 필요합니다.
        // 여기서는 partnerUid가 존재하면, currentPartnerRelation이 null일 경우 임시적인 정보를 만들거나,
        // 혹은 acceptPartnerInvitation을 통해 설정된 값을 신뢰하고 유지합니다.
        // 가장 안전한 방법은 partnerUid가 있는데 currentPartnerRelation이 null이면,
        // "파트너 정보 로딩 중" 상태를 표시하거나, UI에서 partnerUid 존재 유무로 판단하는 것입니다.
        // 지금은 acceptPartnerInvitation을 통해 currentPartnerRelation이 설정된다고 가정합니다.
        // 만약 acceptPartnerInvitation을 통해 설정된 currentPartnerRelation이 있는데,
        // user.partnerUid가 다른 값으로 바뀌었다면(이론상으로는 없어야 함), currentPartnerRelation을 null로 초기화합니다.
        if (kDebugMode) {
          print("[PartnerController] User has partnerUid (${user.partnerUid}). Current relation: ${currentPartnerRelation.value?.partnerUser.userUid}");
        }
        // 여기서 중요한 것은, 로그인 시 서버에서 partnerUid를 받으면,
        // ProfileScreen이 이 정보를 보고 "파트너 있음"으로 판단해야 한다는 것입니다.
        // currentPartnerRelation은 초대 수락 시점에 채워지므로, 로그인만으로는 채워지지 않을 수 있습니다.
      }
      if (currentInvitation.value != null) {
        currentInvitation.value = null; // 파트너가 연결되면 기존 초대 코드는 무효화/숨김
        if (kDebugMode) print("[PartnerController] Cleared invitation code because partner is connected.");
      }
    }
    // 상태 변경을 GetX에 알림 (Obx 등이 반응하도록)
    currentPartnerRelation.refresh();
    currentInvitation.refresh();
  }


  Future<PartnerInvitationResponseDto?> createPartnerInvitationCode() async {
    if (_loginController.user.partnerUid != null && _loginController.user.partnerUid!.isNotEmpty) {
      _setError("이미 파트너와 연결되어 있어 초대 코드를 생성할 수 없습니다.", showGeneralMessageToUser: false);
      return null;
    }
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _loginController.user.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return null;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/partner/invitation');

    try {
      final response = await http.post(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final invitation = PartnerInvitationResponseDto.fromJson(responseData);
        currentInvitation.value = invitation;
        currentPartnerRelation.value = null; // 새 코드 생성 시 기존 파트너 관계는 없다고 간주 (UI 일관성)
        Get.snackbar('성공', '파트너 초대 코드가 생성되었습니다.');
        _setLoading(false);
        return invitation;
      } else if (response.statusCode == 400) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        _setError(responseBody['message'] ?? '잘못된 요청입니다.', showGeneralMessageToUser: false);
      } else {
        _setError('초대 코드 생성 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
      }
    } catch (e, s) {
      _setError('초대 코드 생성 중 예외 발생: $e\n$s');
    }
    _setLoading(false);
    return null;
  }

  Future<PartnerRelationResponseDto?> acceptPartnerInvitation(String invitationId) async {
    if (_loginController.user.partnerUid != null && _loginController.user.partnerUid!.isNotEmpty) {
      _setError("이미 파트너와 연결되어 있어 초대를 수락할 수 없습니다.", showGeneralMessageToUser: false);
      return null;
    }
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _loginController.user.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return null;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/partner/invitation/accept');
    final requestBody = PartnerInvitationAcceptRequestDto(invitationId: invitationId).toJson();

    try {
      final response = await http.post(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final relation = PartnerRelationResponseDto.fromJson(responseData);
        currentPartnerRelation.value = relation;
        _loginController.updateUserPartnerUid(relation.partnerUser.userUid);
        currentInvitation.value = null;
        Get.snackbar('성공', '파트너 초대를 수락했습니다! 이제부터 \'${relation.partnerUser.nickname ?? '파트너'}\'님과 연결됩니다.');
        _setLoading(false);
        return relation;
      } else if (response.statusCode == 400 || response.statusCode == 409 || response.statusCode == 404) {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        _setError(responseBody['message'] ?? '초대 수락에 실패했습니다.', showGeneralMessageToUser: false);
      } else {
        _setError('파트너 초대 수락 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
      }
    } catch (e, s) {
      _setError('파트너 초대 수락 중 예외 발생: $e\n$s');
    }
    _setLoading(false);
    return null;
  }

  Future<void> unfriendPartnerAndClearChat() async {
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _loginController.user.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다. (파트너 해제 실패)');
      _setLoading(false);
      return;
    }

    if (_loginController.user.partnerUid == null || _loginController.user.partnerUid!.isEmpty) {
      if (kDebugMode) {
        print("[PartnerController] No partner to unfriend.");
      }
      _setError('연결된 파트너가 없습니다.', showGeneralMessageToUser: false);
      _setLoading(false);
      return;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/partner');
    try {
      final response = await http.delete(
        requestUri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        if (kDebugMode) {
          print("[PartnerController] Partner relationship and chat history deleted successfully.");
        }
        _loginController.updateUserPartnerUid(null);
        currentPartnerRelation.value = null;
        currentInvitation.value = null;
        Get.snackbar('성공', '파트너 관계가 해제되고 대화 내역이 삭제되었습니다.');
      } else if (response.statusCode == 401) {
        _setError('인증 실패로 파트너 관계를 해제할 수 없습니다.', showGeneralMessageToUser: false);
      } else if (response.statusCode == 404) {
        _setError('사용자 또는 파트너 정보를 찾을 수 없습니다.', showGeneralMessageToUser: false);
      } else {
        final responseBody = json.decode(utf8.decode(response.bodyBytes));
        _setError(responseBody['message'] ?? '파트너 관계 해제 실패 (코드: ${response.statusCode})');
      }
    } catch (e,s) {
      _setError('파트너 관계 해제 중 예외 발생: $e\n$s');
    } finally {
      _setLoading(false);
    }
  }

  void clearPartnerStateOnLogout() {
    currentInvitation.value = null;
    currentPartnerRelation.value = null;
    _clearError();
    _setLoading(false);
    if (kDebugMode) {
      print("[PartnerController] Partner state cleared due to logout/account deletion.");
    }
  }

  // LoginController에서 User 정보가 확정된 후 호출될 수 있도록 public으로 변경
  // 또는 onInit에서 ever(_loginController.obs, ...)를 통해 반응하도록 함 (현재 방식)
  void initializePartnerStatus() {
    _synchronizePartnerStatus(_loginController.user);
  }
}