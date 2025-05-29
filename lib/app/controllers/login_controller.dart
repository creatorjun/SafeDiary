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

  Future<User?> _fetchServiceTokens(User socialUser) async {
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
        final bool isNewFromServer = responseData['isNew'] as bool? ?? socialUser.isNew;
        final String? newAccessToken = responseData['accessToken'] as String?;
        final String? newRefreshToken = responseData['refreshToken'] as String?;
        final bool isAppPasswordSetFromServer = responseData['isAppPasswordSet'] as bool? ?? false;
        final String? partnerUidServer = responseData['partnerUid'] as String?;
        final String? createdAtString = responseData['createdAt'] as String?; // createdAt 파싱
        DateTime? createdAtDate;
        if (createdAtString != null && createdAtString.isNotEmpty) {
          try {
            createdAtDate = DateTime.parse(createdAtString);
          } catch (e) {
            if (kDebugMode) {
              print("[LoginController] Error parsing createdAt from server: $e");
            }
          }
        }

        User updatedUser = socialUser.copyWith(
          safeAccessToken: newAccessToken,
          safeRefreshToken: newRefreshToken,
          isNew: isNewFromServer,
          isAppPasswordSet: isAppPasswordSetFromServer,
          partnerUid: partnerUidServer,
          createdAt: createdAtDate, // createdAt 업데이트
        );

        if (updatedUser.id != null && newRefreshToken != null) {
          await _secureStorageService.saveUserAuthData(
            refreshToken: newRefreshToken,
            accessToken: newAccessToken,
            userId: updatedUser.id!,
            platform: updatedUser.platform.name,
            nickname: updatedUser.nickname,
            isNew: updatedUser.isNew,
            userCreatedAt: updatedUser.createdAt?.toIso8601String(), // createdAt 저장 (ISO8601 문자열)
          );
        }
        return updatedUser;
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
                    if (kDebugMode) {
                      print('[LoginController] Naver Profile API Success: $response');
                    }
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
                    );
                    User? userWithServiceJwt = await _fetchServiceTokens(socialUser);
                    if (userWithServiceJwt != null) {
                      _user.value = userWithServiceJwt;
                      Get.offAllNamed(Routes.HOME);
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
            if (message.contains('user_cancel') || message.contains('closed') || errorCode == 'user_cancel') {
              _setError('네이버 로그인이 사용자에 의해 취소되었습니다.', showGeneralMessageToUser: false);
            } else if (message.contains('naverapp_not_installed')) {
              _setError('네이버 앱이 설치되어 있지 않습니다. 웹으로 로그인을 시도합니다.', showGeneralMessageToUser: false);
            } else {
              _setError('네이버 로그인 인증 오류: $errorCode - $message');
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

      User? userWithServiceJwt = await _fetchServiceTokens(socialUser);
      if (userWithServiceJwt != null) {
        _user.value = userWithServiceJwt;
        Get.offAllNamed(Routes.HOME);
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
      await _secureStorageService.clearUserAuthData(); // createdAt 포함 모든 데이터 삭제
      LoginPlatform currentPlatform = _user.value.platform;
      if (currentPlatform == LoginPlatform.naver) {
        await NaverLoginSDK.release();
      } else if (currentPlatform == LoginPlatform.kakao) {
        await kakao.UserApi.instance.logout();
      }
      _user.value = User(platform: LoginPlatform.none, isNew: false, isAppPasswordSet: false, createdAt: null); // createdAt 초기화
      Get.snackbar('로그아웃', '성공적으로 로그아웃되었습니다.');
      Get.offAllNamed(Routes.LOGIN);
    } catch (error, stackTrace) {
      _setError('logout() 중 오류: $error\n$stackTrace');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLoginWithRefreshToken() async {
    _setLoading(true);
    _clearError();
    try {
      final storedData = await _secureStorageService.getUserAuthData();
      if (storedData == null || storedData[SecureStorageService.keyRefreshToken] == null) {
        _setLoading(false);
        return false;
      }

      final String refreshToken = storedData[SecureStorageService.keyRefreshToken]!;
      final String? baseUrl = AppConfig.apiUrl;
      if (baseUrl == null) {
        _setError('API URL이 설정되지 않았습니다.');
        _setLoading(false);
        return false;
      }

      final Uri refreshUri = Uri.parse('$baseUrl/api/v1/auth/refresh');
      final refreshResponse = await http.post(
        refreshUri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $refreshToken'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final responseData = json.decode(refreshResponse.body);
        final String? newAccessToken = responseData['accessToken'] as String?;
        final String? newRefreshToken = responseData['refreshToken'] as String?;

        final String refreshedUserId = responseData['id'] as String? ?? storedData[SecureStorageService.keyUserId] ?? "";
        final String refreshedNickname = responseData['nickname'] as String? ?? storedData[SecureStorageService.keyNickname] ?? "";
        final LoginPlatform refreshedPlatform = LoginPlatform.values.firstWhere(
                (e) => e.name == (responseData['platform'] as String? ?? storedData[SecureStorageService.keyPlatform]),
            orElse: () => LoginPlatform.none);
        final bool refreshedIsNew = responseData['isNew'] as bool? ?? (storedData[SecureStorageService.keyIsNew]?.toLowerCase() == 'true');
        final bool refreshedIsAppPasswordSet = responseData['isAppPasswordSet'] as bool? ?? false;
        final String? refreshedPartnerUid = responseData['partnerUid'] as String?;

        // createdAt 로드 및 파싱
        final String? createdAtStringFromServer = responseData['createdAt'] as String?;
        final String? createdAtStringFromStorage = storedData[SecureStorageService.keyUserCreatedAt];
        DateTime? refreshedCreatedAt;

        String? finalCreatedAtString = createdAtStringFromServer ?? createdAtStringFromStorage;

        if (finalCreatedAtString != null && finalCreatedAtString.isNotEmpty) {
          try {
            refreshedCreatedAt = DateTime.parse(finalCreatedAtString);
          } catch (e) {
            if (kDebugMode) {
              print("[LoginController] Error parsing createdAt during auto-login: $e");
            }
          }
        }


        if (newAccessToken != null && refreshedUserId.isNotEmpty) {
          _user.value = User(
            id: refreshedUserId,
            nickname: refreshedNickname,
            platform: refreshedPlatform,
            isNew: refreshedIsNew,
            safeAccessToken: newAccessToken,
            safeRefreshToken: newRefreshToken ?? refreshToken,
            isAppPasswordSet: refreshedIsAppPasswordSet,
            partnerUid: refreshedPartnerUid,
            createdAt: refreshedCreatedAt, // createdAt 설정
          );

          await _secureStorageService.saveUserAuthData(
            refreshToken: newRefreshToken ?? refreshToken,
            accessToken: newAccessToken,
            userId: _user.value.id!,
            platform: _user.value.platform.name,
            nickname: _user.value.nickname,
            isNew: _user.value.isNew,
            userCreatedAt: _user.value.createdAt?.toIso8601String(), // createdAt 저장
          );
          _setLoading(false);
          return true;
        }
      } else {
        await _secureStorageService.clearUserAuthData();
        _setError('토큰 갱신 실패 (코드: ${refreshResponse.statusCode}), 응답: ${refreshResponse.body}');
      }
    } catch (e,s) {
      _setError('자동 로그인 시도 중 예외 발생: $e\n$s');
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        _user.value = _user.value.copyWith(nickname: newNickname);
        _user.refresh();
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
        _setError('앱 비밀번호가 일치하지 않습니다.', showGeneralMessageToUser: false);
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

      print(requestBody);

      if (response.statusCode == 200 || response.statusCode == 204) {
        _user.value = _user.value.copyWith(isAppPasswordSet: true);
        _user.refresh();
        Get.snackbar('성공', '앱 비밀번호가 성공적으로 설정/변경되었습니다.');
        _setLoading(false);
        return true;
      } else if (response.statusCode == 401 && currentAppPassword != null) {
        _setError('현재 앱 비밀번호가 일치하지 않습니다.', showGeneralMessageToUser: false);
        _setLoading(false);
        return false;
      }
      else {
        _setError('앱 비밀번호 설정/변경 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
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
        _user.refresh();
        Get.snackbar('성공', '앱 비밀번호가 성공적으로 해제되었습니다.');
        _setLoading(false);
        return true;
      } else if (response.statusCode == 401) {
        _setError('현재 앱 비밀번호가 일치하지 않아 해제할 수 없습니다.', showGeneralMessageToUser: false);
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

  Future<void> unfriendPartnerAndClearChat() async {
    final String? baseUrl = AppConfig.apiUrl;
    final String? token = _user.value.safeAccessToken;

    if (baseUrl == null || token == null) {
      _setError('API URL 또는 사용자 토큰이 유효하지 않습니다. (파트너 해제 실패)');
      return;
    }

    if (_user.value.partnerUid == null || _user.value.partnerUid!.isEmpty) {
      if (kDebugMode) {
        print("[LoginController] No partner to unfriend.");
      }
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
          print("[LoginController] Partner relationship and chat history deleted successfully.");
        }
        _user.value = _user.value.copyWith(partnerUid: null);
        _user.refresh();
        Get.snackbar('알림', '파트너 관계가 해제되고 대화 내역이 삭제되었습니다.');
      } else if (response.statusCode == 401) {
        _setError('인증 실패로 파트너 관계를 해제할 수 없습니다. (코드: ${response.statusCode})', showGeneralMessageToUser: false);
      } else if (response.statusCode == 404) {
        _setError('사용자 또는 파트너 정보를 찾을 수 없습니다. (코드: ${response.statusCode})', showGeneralMessageToUser: false);
      }
      else {
        _setError('파트너 관계 해제 실패 (코드: ${response.statusCode}), 응답: ${response.body}');
      }
    } catch (e,s) {
      _setError('파트너 관계 해제 중 예외 발생: $e\n$s');
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
        await unfriendPartnerAndClearChat();
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
        await _secureStorageService.clearUserAuthData();
        _user.value = User(platform: LoginPlatform.none, isNew: false, isAppPasswordSet: false, partnerUid: null, createdAt: null); // createdAt 초기화
        Get.offAllNamed(Routes.LOGIN);
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