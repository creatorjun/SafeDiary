// lib/app/models/user.dart

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // DateFormat 사용을 위해 추가

enum LoginPlatform {
  naver,
  kakao,
  none;

  String toJson() => name;

  static LoginPlatform fromJson(String jsonValue) {
    return LoginPlatform.values.firstWhere(
          (e) => e.name == jsonValue,
      orElse: () => LoginPlatform.none,
    );
  }
}

class User {
  final LoginPlatform platform;
  final String? id; // 서버에서 발급하는 고유 ID (이전 socialId와 다름)
  final String? nickname;
  final String? partnerUid;
  final String? partnerNickname; // 파트너의 닉네임 필드 추가

  final String? socialAccessToken; // 소셜 플랫폼의 Access Token (필요시 저장)
  final String? safeAccessToken; // 우리 서비스의 Access Token
  final String? safeRefreshToken; // 우리 서비스의 Refresh Token

  final bool isNew;
  final bool isAppPasswordSet;
  final DateTime? createdAt;

  User({
    required this.platform,
    this.id,
    this.nickname,
    this.partnerUid,
    this.partnerNickname, // 생성자에 추가
    this.socialAccessToken,
    this.safeAccessToken,
    this.safeRefreshToken,
    this.isNew = false,
    this.isAppPasswordSet = false,
    this.createdAt,
  });

  User copyWith({
    LoginPlatform? platform,
    String? id,
    String? nickname,
    String? partnerUid,
    String? partnerNickname, // copyWith에 추가
    String? socialAccessToken,
    String? safeAccessToken,
    String? safeRefreshToken,
    bool? isNew,
    bool? isAppPasswordSet,
    DateTime? createdAt,
  }) {
    return User(
      platform: platform ?? this.platform,
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      partnerUid: partnerUid ?? this.partnerUid,
      partnerNickname: partnerNickname ?? this.partnerNickname, // copyWith에 로직 추가
      socialAccessToken: socialAccessToken ?? this.socialAccessToken,
      safeAccessToken: safeAccessToken ?? this.safeAccessToken,
      safeRefreshToken: safeRefreshToken ?? this.safeRefreshToken,
      isNew: isNew ?? this.isNew,
      isAppPasswordSet: isAppPasswordSet ?? this.isAppPasswordSet,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    // toJson은 주로 클라이언트에서 서버로 User 객체를 보낼 때 사용되는데,
    // 현재 User 모델은 서버 응답을 받아 클라이언트에서 사용하는 형태이므로,
    // 이 메서드가 현재 사용되는지는 확인이 필요합니다.
    // 만약 사용된다면 partnerNickname도 포함할 수 있습니다.
    return {
      'platform': platform.toJson(),
      'id': id,
      'nickname': nickname,
      'partnerUid': partnerUid,
      'partnerNickname': partnerNickname, // toJson에 추가 (필요시)
      'socialAccessToken': socialAccessToken,
      'safeAccessToken': safeAccessToken,
      'safeRefreshToken': safeRefreshToken,
      'isNew': isNew,
      'isAppPasswordSet': isAppPasswordSet,
      // 'createdAt': createdAt?.toIso8601String(), // 필요시
    };
  }

  // fromJson은 현재 LoginController에서 직접 API 응답을 파싱하여 User 객체를 생성하므로,
  // 이 메서드는 현재 직접적으로 사용되지 않을 수 있습니다.
  // 만약 사용된다면 partnerNickname 파싱 로직을 추가해야 합니다.
  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null && (json['createdAt'] as String).isNotEmpty) {
      try {
        parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        // 파싱 실패 시 createdAt은 null로 유지
        if (kDebugMode) {
          print('Error parsing createdAt in User.fromJson: $e');
        }
      }
    }

    return User(
      platform: LoginPlatform.fromJson(
        // API 응답에서는 'loginProvider' 필드를 사용하고, User 모델에서는 'platform'을 사용하므로 주의
        json['platform'] as String? ?? LoginPlatform.none.name,
      ),
      // API 응답에서는 'uid' 필드를 사용하고, User 모델에서는 'id'를 사용하므로 주의
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      partnerUid: json['partnerUid'] as String?,
      partnerNickname: json['partnerNickname'] as String?, // fromJson에 추가
      socialAccessToken: json['socialAccessToken'] as String?,
      safeAccessToken: json['safeAccessToken'] as String?,
      safeRefreshToken: json['safeRefreshToken'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      // API 응답에서는 'appPasswordSet' 필드를 사용하고, User 모델에서는 'isAppPasswordSet'을 사용하므로 주의
      isAppPasswordSet: json['isAppPasswordSet'] as bool? ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  String get formattedCreatedAt {
    if (createdAt == null) return '';
    return DateFormat('yy년 MM월 dd일', 'ko_KR').format(createdAt!);
  }

  @override
  String toString() {
    return 'User(platform: $platform, id: $id, nickname: $nickname, partnerUid: $partnerUid, partnerNickname: $partnerNickname, socialAccessToken: $socialAccessToken, safeAccessToken: $safeAccessToken, safeRefreshToken: $safeRefreshToken, isNew: $isNew, isAppPasswordSet: $isAppPasswordSet, createdAt: ${createdAt?.toIso8601String()})';
  }
}