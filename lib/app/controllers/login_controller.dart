// lib/app/controllers/login_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_user.dart' as kakao;
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../routes/app_pages.dart';
import '../config/app_config.dart';
import '../services/secure_storage_service.dart';
import 'partner_controller.dart';

class LoginController extends GetxController {
  final SecureStorageService _secureStorageService = SecureStorageService();

  final Rx<User> _user = User(platform: LoginPlatform.none, isNew: false, isAppPasswordSet: false).obs;
  User get user => _user.value;

  RxBool get isLoggedIn => (_user.value.platform != LoginPlatform.none).obs;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  final String _generalErrorMessage = "오류가 발생했습니다. 문제가 지속되면 관리자에게 문의하세요.";

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void _setError(String detailedLogMessage, {bool showGeneralMessageToUser = true}) {
    if (kDebugMode) {
      print("[LoginController] Detailed Error: $detailedLogMessage");
    }
    if (showGeneralMessageToUser) {
      _errorMessage.value = _generalErrorMessage;
    } else {
      _errorMessage.value = detailedLogMessage;
    }
  }

  void updateUserPartnerUid(String? newPartnerUid) {
    if (_user.value.partnerUid != newPartnerUid) {
      _user.value = _user.value.copyWith(partnerUid: newPartnerUid);
      if (kDebugMode) {
        print("[LoginController] User's partnerUid updated to: $newPartnerUid.");
      }
    }
  }

  Future<User?> _fetchServiceTokensAndUpdateUser(User socialUser) async {
    final String? baseUrl = AppConfig.apiUrl;
    if (baseUrl == null) {
      _setError('API URL이 설정되지 않았습니다. (관리자 문의)');
      return null;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/auth/social/login');
    final requestBody = {
      'id': socialUser.id,
      'nickname': socialUser.nickname,
      'platform': socialUser.platform.name,
      'socialAccessToken': socialUser.socialAccessToken,
    };

    try {
      final response = await http.post(
        requestUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user.value = User(
          platform: LoginPlatform.values.firstWhere(
                (e) => e.name == (responseData['loginProvider'] as String?),
            orElse: () => socialUser.platform,
          ),
          id: responseData['uid'] as String? ?? socialUser.id,
          nickname: responseData['nickname'] as String? ?? socialUser.nickname,
          partnerUid: responseData['partnerUid'] as String?,
          partnerNickname: responseData['partnerNickname'] as String?, // partnerNickname 파싱 추가
          socialAccessToken: socialUser.socialAccessToken,
          safeAccessToken: responseData['accessToken'] as String?,
          safeRefreshToken: responseData['refreshToken'] as String?,
          isNew: responseData['isNew'] as bool? ?? socialUser.isNew,
          isAppPasswordSet: responseData['appPasswordSet'] as bool? ?? false,
          createdAt: responseData['createdAt'] != null ? DateTime.tryParse(responseData['createdAt']) : null,
        );

        if(kDebugMode){
          print(user.toString());
        }

        if (_user.value.safeRefreshToken != null) {
          await _secureStorageService.saveRefreshToken(refreshToken: _user.value.safeRefreshToken!);
        }
        return _user.value;
      } else {
        _setError('서버 통신 오류 (코드: ${response.statusCode}), 응답: ${response.body}');
        return null;
      }
    } catch (e, s) {
      _setError('서비스 토큰 요청 중 예외 발생: $e\n$s');
      return null;
    }
  }

  Future<void> loginWithNaver() async {
    _setLoading(true);
    _clearError();
    try {
      NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () async {
            NaverLoginSDK.profile(callback: ProfileCallback(
                onSuccess: (resultCode, message, response) async {
                  try {
                    final profile = NaverLoginProfile.fromJson(response: response);
                    final String naverSocialToken = await NaverLoginSDK.getAccessToken();
                    final String rawId = profile.id ?? "";

                    if (rawId.isEmpty) {
                      _setError('네이버 사용자 ID를 가져올 수 없습니다.');
                      _setLoading(false);
                      return;
                    }
                    User socialUser = User(
                      platform: LoginPlatform.naver,
                      id: rawId,
                      nickname: profile.nickName,
                      socialAccessToken: naverSocialToken,
                      // partnerNickname은 소셜 로그인 시점에는 알 수 없음
                    );
                    User? updatedUser = await _fetchServiceTokensAndUpdateUser(socialUser);
                    if (updatedUser != null) {
                      Get.offAllNamed(Routes.home);
                    }
                  } catch (e,s) {
                    _setError('네이버 프로필 처리 중 오류: $e\n$s');
                  } finally {
                    _setLoading(false);
                  }
                },
                onFailure: (httpStatus, message) {
                  _setError('네이버 프로필 요청 실패: HTTP $httpStatus - $message');
                  _setLoading(false);
                },
                onError: (errorCode, message) {
                  _setError('네이버 프로필 요청 오류: $errorCode - $message');
                  _setLoading(false);
                }
            ));
          },
          onFailure: (httpStatus, message) {
            _setError('네이버 로그인 인증 실패: HTTP $httpStatus - $message');
            _setLoading(false);
          },
            onError: (errorCode, message) {
              // errorCode를 문자열로 변환하여 비교하거나, SDK 명세에 따른 정확한 타입/값으로 비교
              final String errorCodeStr = errorCode.toString(); // errorCode를 문자열로 변환

              // 네이버 SDK의 실제 사용자 취소 코드값 확인 필요 (예시로 'user_cancel' 문자열 비교 포함)
              // SDK 문서나 테스트를 통해 정확한 int 값을 확인하고 해당 값으로 비교하는 것이 가장 좋습니다.
              // 예를 들어, 사용자 취소가 특정 숫자 코드 (예: 1, -100 등)로 온다면
              // if (errorCode == 1 || errorCode == -100 || message.contains('user_cancel') || message.contains('closed'))
              // 와 같이 조건을 구성해야 합니다.

              if (message.contains('user_cancel') || // 메시지 기반 체크 (보조적)
                  message.contains('closed') || // 메시지 기반 체크 (보조적)
                  errorCodeStr == 'user_cancel' || // 문자열화된 코드 비교 (SDK가 문자열 코드를 반환하는 경우)
                  // 여기에 실제 네이버 SDK가 사용자 취소 시 반환하는 int errorCode 값을 넣어야 합니다.
                  // 예: errorCode == NaverLoginErrors.USER_CANCELLED (SDK에 이런 enum이 있다면)
                  // 예: errorCode == 123 (SDK가 특정 숫자 코드를 반환한다면)
                  (errorCode == 2) // 예시: 만약 사용자 취소가 int 0으로 온다면
              ) {
                _setError('네이버 로그인이 사용자에 의해 취소되었습니다.', showGeneralMessageToUser: false);
              } else if (message.contains('naverapp_not_installed') || message.contains("not_available_naver_app")) {
                _setError('네이버 앱이 설치되어 있지 않거나 사용할 수 없습니다. 웹으로 로그인을 시도합니다.', showGeneralMessageToUser: false);
              } else {
                _setError('네이버 로그인 인증 오류: $errorCodeStr - $message');
              }
              _setLoading(false);
            },
        ),
      );
    } catch (error,s) {
      _setError('네이버 로그인 시도 중 예외: $error\n$s');
      _setLoading(false);
    }
  }


  Future<void> loginWithKakao() async {
    _setLoading(true);
    _clearError();
    try {
      bool isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();
      kakao.OAuthToken kakaoToken;
      if (isKakaoTalkInstalled) {
        try {
          kakaoToken = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            _setError('카카오톡 로그인이 취소되었습니다.', showGeneralMessageToUser: false);
            _setLoading(false);
            return;
          }
          kakaoToken = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        kakaoToken = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final kakao.User kakaoApiUser = await kakao.UserApi.instance.me();
      final String rawId = kakaoApiUser.id.toString();
      if (rawId.isEmpty) {
        _setError('카카오 사용자 ID를 가져올 수 없습니다.');
        _setLoading(false);
        return;
      }
      User socialUser = User(
        platform: LoginPlatform.kakao,
        id: rawId,
        nickname: kakaoApiUser.kakaoAccount?.profile?.nickname,
        socialAccessToken: kakaoToken.accessToken,
      );
      User? updatedUser = await _fetchServiceTokensAndUpdateUser(socialUser);
      if (updatedUser != null) {
        Get.offAllNamed(Routes.home);
      }
    } catch (error,s) {
      _setError('카카오 로그인 중 오류 발생: $error\n$s');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    try {
      if (Get.isRegistered<PartnerController>()) {
        Get.find<PartnerController>().clearPartnerStateOnLogout();
      }

      await _secureStorageService.clearRefreshToken();
      LoginPlatform currentPlatform = _user.value.platform;
      if (currentPlatform == LoginPlatform.naver) {
        await NaverLoginSDK.release();
      } else if (currentPlatform == LoginPlatform.kakao) {
        await kakao.UserApi.instance.logout();
      }
      _user.value = User(platform: LoginPlatform.none, isNew: false, isAppPasswordSet: false, createdAt: null, partnerNickname: null); // partnerNickname 초기화
      Get.snackbar('로그아웃', '성공적으로 로그아웃되었습니다.');
      Get.offAllNamed(Routes.login);
    } catch (error, stackTrace) {
      _setError('logout() 중 오류: $error\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLoginWithRefreshToken() async {
    _setLoading(true);
    _clearError();
    http.Response refreshResponse;

    try {
      final String? storedRefreshToken = await _secureStorageService.getRefreshToken();
      if (storedRefreshToken == null) {
        _setLoading(false);
        return false;
      }

      final String? baseUrl = AppConfig.apiUrl;
      if (baseUrl == null) {
        _setError('API URL이 설정되지 않았습니다.');
        _setLoading(false);
        return false;
      }

      final Uri refreshUri = Uri.parse('$baseUrl/api/v1/auth/refresh');
      refreshResponse = await http.post( // <--- 여기서 refreshResponse에 값이 할당됨
        refreshUri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $storedRefreshToken'},
        body: json.encode({'refreshToken': storedRefreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final responseData = json.decode(refreshResponse.body);
        final String? newAccessToken = responseData['accessToken'] as String?;
        final String? newRefreshToken = responseData['refreshToken'] as String?;

        _user.value = User(
          id: responseData['uid'] as String? ?? "",
          nickname: responseData['nickname'] as String?,
          platform: LoginPlatform.values.firstWhere(
                  (e) => e.name == (responseData['loginProvider'] as String?),
              orElse: () => LoginPlatform.none),
          isNew: responseData['isNew'] as bool? ?? false,
          safeAccessToken: newAccessToken,
          safeRefreshToken: newRefreshToken ?? storedRefreshToken,
          isAppPasswordSet: responseData['appPasswordSet'] as bool? ?? false,
          partnerUid: responseData['partnerUid'] as String?,
          partnerNickname: responseData['partnerNickname'] as String?,
          createdAt: responseData['createdAt'] != null ? DateTime.tryParse(responseData['createdAt']) : null,
        );

        if(kDebugMode){
          print(_user.value.toString());
        }

        if (_user.value.safeRefreshToken != null) {
          await _secureStorageService.saveRefreshToken(refreshToken: _user.value.safeRefreshToken!);
        }
        _setLoading(false);
        return true;
      } else { // <--- 이 블록에 도달했다면 refreshResponse는 이미 값이 할당된 상태여야 함
        await _secureStorageService.clearRefreshToken();
        // 여기서 'response' 대신 'refreshResponse'를 사용해야 함
        _setError('토큰 갱신 실패 (코드: ${refreshResponse.statusCode}), 응답: ${refreshResponse.body}');
      }
    } catch (e,s) { // 네트워크 오류 등 http.post 자체가 실패한 경우
      _setError('자동 로그인 시도 중 예외 발생: $e\n$s');
      // 이 경우 refreshResponse는 초기화되지 않았을 수 있음
    }
    _setLoading(false);
    return false;
  }
  Future<void> updateUserNickname(String newNickname) async {
    if (newNickname.trim().isEmpty) {
      Get.snackbar('오류', '닉네임은 비워둘 수 없습니다.');
      return;
    }
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;
    if (baseUrl == null || token == null) {
      _setError('API URL 또는 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'nickname': newNickname}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user.value = _user.value.copyWith(
          nickname: responseData['nickname'] as String? ?? newNickname,
          isAppPasswordSet: responseData['appPasswordSet'] as bool? ?? _user.value.isAppPasswordSet,
        );
        Get.snackbar('성공', '닉네임이 성공적으로 변경되었습니다.');
      } else {
        _setError('닉네임 변경 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
      }
    } catch (e,s) {
      _setError('닉네임 변경 중 오류 발생: $e\n$s');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyAppPasswordWithServer(String appPassword) async {
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return false;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/verify-app-password');
    try {
      final response = await http.post(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'appPassword': appPassword}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _setLoading(false);
        return responseData['isVerified'] as bool? ?? false;
      } else if (response.statusCode == 401) {
        final responseData = json.decode(response.body);
        _setError(responseData['message'] ?? '앱 비밀번호가 일치하지 않습니다.', showGeneralMessageToUser: false);
        _setLoading(false);
        return false;
      }
      else {
        _setError('앱 비밀번호 검증 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
        _setLoading(false);
        return false;
      }
    } catch (e,s) {
      _setError('앱 비밀번호 검증 중 예외 발생: $e\n$s');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> setAppPasswordOnServer(String? currentAppPassword, String newAppPassword) async {
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return false;
    }

    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me');
    Map<String, String?> requestBody = {'newAppPassword': newAppPassword};
    if (currentAppPassword != null && currentAppPassword.isNotEmpty) {
      requestBody['currentAppPassword'] = currentAppPassword;
    }

    try {
      final response = await http.patch(
        requestUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user.value = _user.value.copyWith(
          isAppPasswordSet: responseData['appPasswordSet'] as bool? ?? true,
          nickname: responseData['nickname'] as String? ?? _user.value.nickname,
          // partnerNickname은 이 API 응답에 포함되어 있지 않음 (Swagger UserAccountUpdateResponseDto 기준)
          // partnerNickname: responseData['partnerNickname'] as String? ?? _user.value.partnerNickname,
        );
        Get.snackbar('성공', '앱 비밀번호가 성공적으로 설정/변경되었습니다.');
        _setLoading(false);
        return true;
      } else if (response.statusCode == 401 && currentAppPassword != null) {
        final responseData = json.decode(response.body);
        _setError(responseData['message'] ?? '현재 앱 비밀번호가 일치하지 않습니다.', showGeneralMessageToUser: false);
        _setLoading(false);
        return false;
      }
      else {
        final responseData = json.decode(response.body);
        _setError(responseData['message'] ?? '앱 비밀번호 설정/변경 실패 (코드: ${response.statusCode})');
        _setLoading(false);
        return false;
      }
    } catch (e,s) {
      _setError('앱 비밀번호 설정/변경 중 예외 발생: $e\n$s');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeAppPasswordOnServer(String currentAppPassword) async {
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return false;
    }
    final Uri requestUri = Uri.parse('$baseUrl/api/v1/users/me/app-password');

    try {
      final request = http.Request('DELETE', requestUri);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = json.encode({'currentAppPassword': currentAppPassword});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 204) {
        _user.value = _user.value.copyWith(isAppPasswordSet: false);
        Get.snackbar('성공', '앱 비밀번호가 성공적으로 해제되었습니다.');
        _setLoading(false);
        return true;
      } else if (response.statusCode == 401) {
        String errorMessage = '현재 앱 비밀번호가 일치하지 않아 해제할 수 없습니다.';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody['message'] != null) {
            errorMessage = responseBody['message'];
          }
        } catch (_) {}
        _setError(errorMessage, showGeneralMessageToUser: false);
        _setLoading(false);
        return false;
      }
      else {
        _setError('앱 비밀번호 해제 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
        _setLoading(false);
        return false;
      }
    } catch (e,s) {
      _setError('앱 비밀번호 해제 중 예외 발생: $e\n$s');
      _setLoading(false);
      return false;
    }
  }

  Future<void> processAccountDeletion() async {
    _setLoading(true);
    _clearError();
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다.');
      _setLoading(false);
      return;
    }

    try {
      if (_user.value.partnerUid != null && _user.value.partnerUid!.isNotEmpty) {
        if (Get.isRegistered<PartnerController>()) {
          await Get.find<PartnerController>().unfriendPartnerAndClearChat();
        }
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        LoginPlatform currentPlatform = _user.value.platform;
        if (currentPlatform == LoginPlatform.naver) {
        } else if (currentPlatform == LoginPlatform.kakao) {
          try {
            await kakao.UserApi.instance.unlink();
          } catch (unlinkError) {
            if (kDebugMode) print("Kakao unlink error: $unlinkError");
          }
        }
        await _secureStorageService.clearRefreshToken();
        _user.value = User(platform: LoginPlatform.none, isNew: false, isAppPasswordSet: false, partnerUid: null, createdAt: null, partnerNickname: null); // partnerNickname 초기화

        if (Get.isRegistered<PartnerController>()) {
          Get.find<PartnerController>().clearPartnerStateOnLogout();
        }

        Get.offAllNamed(Routes.login);
        Get.snackbar('회원 탈퇴 완료', '회원 탈퇴가 성공적으로 처리되었습니다.');
      } else {
        _setError('회원 탈퇴 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
      }
    } catch (error,s) {
      _setError('회원 탈퇴 처리 중 오류 발생: $error\n$s');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) print('[LoginController] onInit called.');
  }
}