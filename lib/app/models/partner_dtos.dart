// lib/app/models/partner_dtos.dart

class PartnerUserInfoDto {
  final String userUid;
  final String? nickname;

  PartnerUserInfoDto({
    required this.userUid,
    this.nickname,
  });

  factory PartnerUserInfoDto.fromJson(Map<String, dynamic> json) {
    return PartnerUserInfoDto(
      userUid: json['userUid'] as String,
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userUid': userUid,
      'nickname': nickname,
    };
  }
}

class PartnerInvitationResponseDto {
  final String invitationId;
  final String expiresAt; // ISO 8601 DateTime String

  PartnerInvitationResponseDto({
    required this.invitationId,
    required this.expiresAt,
  });

  factory PartnerInvitationResponseDto.fromJson(Map<String, dynamic> json) {
    return PartnerInvitationResponseDto(
      invitationId: json['invitationId'] as String,
      expiresAt: json['expiresAt'] as String,
    );
  }
}

class PartnerInvitationAcceptRequestDto {
  final String invitationId;

  PartnerInvitationAcceptRequestDto({
    required this.invitationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
    };
  }
}

class PartnerRelationResponseDto {
  final String message;
  final PartnerUserInfoDto currentUser;
  final PartnerUserInfoDto partnerUser;
  final String partnerSince; // ISO 8601 DateTime String

  PartnerRelationResponseDto({
    required this.message,
    required this.currentUser,
    required this.partnerUser,
    required this.partnerSince,
  });

  factory PartnerRelationResponseDto.fromJson(Map<String, dynamic> json) {
    return PartnerRelationResponseDto(
      message: json['message'] as String,
      currentUser: PartnerUserInfoDto.fromJson(json['currentUser'] as Map<String, dynamic>),
      partnerUser: PartnerUserInfoDto.fromJson(json['partnerUser'] as Map<String, dynamic>),
      partnerSince: json['partnerSince'] as String,
    );
  }
}