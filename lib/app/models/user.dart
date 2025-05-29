// lib/app/models/user.dart

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
  final String? id;
  final String? nickname;
  final String? partnerUid;

  final String? socialAccessToken;
  final String? safeAccessToken;
  final String? safeRefreshToken;

  final bool isNew;
  final bool isAppPasswordSet;
  final DateTime? createdAt; // 사용자 계정 생성 시각 필드 추가

  User({
    required this.platform,
    this.id,
    this.nickname,
    this.partnerUid,
    this.socialAccessToken,
    this.safeAccessToken,
    this.safeRefreshToken,
    this.isNew = false,
    this.isAppPasswordSet = false,
    this.createdAt, // 생성자에 추가
  });

  User copyWith({
    LoginPlatform? platform,
    String? id,
    String? nickname,
    String? partnerUid,
    String? socialAccessToken,
    String? safeAccessToken,
    String? safeRefreshToken,
    bool? isNew,
    bool? isAppPasswordSet,
    DateTime? createdAt, // copyWith에 추가
  }) {
    return User(
      platform: platform ?? this.platform,
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      partnerUid: partnerUid ?? this.partnerUid,
      socialAccessToken: socialAccessToken ?? this.socialAccessToken,
      safeAccessToken: safeAccessToken ?? this.safeAccessToken,
      safeRefreshToken: safeRefreshToken ?? this.safeRefreshToken,
      isNew: isNew ?? this.isNew,
      isAppPasswordSet: isAppPasswordSet ?? this.isAppPasswordSet,
      createdAt: createdAt ?? this.createdAt, // copyWith에 추가
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform.toJson(),
      'id': id,
      'nickname': nickname,
      'partnerUid': partnerUid,
      'socialAccessToken': socialAccessToken,
      'safeAccessToken': safeAccessToken,
      'safeRefreshToken': safeRefreshToken,
      'isNew': isNew,
      'isAppPasswordSet': isAppPasswordSet,
      // createdAt은 보통 클라이언트에서 서버로 전송하지 않으므로 toJson에는 포함하지 않을 수 있습니다.
      // 만약 필요하다면 ISO8601 문자열로 변환하여 추가:
      // 'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCreatedAt;
    if (json['createdAt'] != null && (json['createdAt'] as String).isNotEmpty) {
      try {
        parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        // 파싱 실패 시 createdAt은 null로 유지
        print('Error parsing createdAt: $e');
      }
    }

    return User(
      platform: LoginPlatform.fromJson(
        json['platform'] as String? ?? LoginPlatform.none.name,
      ),
      id: json['id'] as String?,
      nickname: json['nickname'] as String?,
      partnerUid: json['partnerUid'] as String?,
      socialAccessToken: json['socialAccessToken'] as String?,
      safeAccessToken: json['safeAccessToken'] as String?,
      safeRefreshToken: json['safeRefreshToken'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isAppPasswordSet: json['isAppPasswordSet'] as bool? ?? false,
      createdAt: parsedCreatedAt, // fromJson에 추가
    );
  }

  String get formattedCreatedAt {
    if (createdAt == null) return '';
    // YY년 MM월 DD일 형식
    return DateFormat('yy년 MM월 dd일', 'ko_KR').format(createdAt!);
  }

  @override
  String toString() {
    return 'User(platform: $platform, id: $id, nickname: $nickname, partnerUid: $partnerUid, socialAccessToken: $socialAccessToken, safeAccessToken: $safeAccessToken, safeRefreshToken: $safeRefreshToken, isNew: $isNew, isAppPasswordSet: $isAppPasswordSet, createdAt: ${createdAt?.toIso8601String()})';
  }
}