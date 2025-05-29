// lib/app/models/social_user.dart

// 로그인 플랫폼 정의
enum LoginPlatform {
  naver, // 네이버
  kakao, // 카카오
  none,  // 로그아웃 상태 또는 초기 상태
}

// 소셜 로그인 사용자 정보 모델
class SocialUser {
  final LoginPlatform platform; // 로그인한 플랫폼
  final String? id; // 사용자 고유 ID (이제 단방향 해시된 값)
  final String? nickname; // 사용자 닉네임

  SocialUser({
    required this.platform,
    this.id,
    this.nickname,
  });

  // 객체 정보를 문자열로 표현하여 디버깅 시 용이하도록 함
  @override
  String toString() {
    return 'SocialUser(platform: $platform, id: $id, nickname: $nickname)';
  }
}