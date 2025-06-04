
class ZodiacLuckData {
  final String requestDate; // API는 date string으로 반환하지만, DateTime으로 파싱해서 사용 가능
  final String zodiacName;
  final List<String> applicableYears;
  final String? overallLuck;
  final String? financialLuck;
  final String? loveLuck;
  final String? healthLuck;
  final int? luckyNumber;
  final String? luckyColor;
  final String? advice;

  ZodiacLuckData({
    required this.requestDate,
    required this.zodiacName,
    required this.applicableYears,
    this.overallLuck,
    this.financialLuck,
    this.loveLuck,
    this.healthLuck,
    this.luckyNumber,
    this.luckyColor,
    this.advice,
  });

  factory ZodiacLuckData.fromJson(Map<String, dynamic> json) {
    return ZodiacLuckData(
      requestDate: json['requestDate'] as String? ?? '',
      zodiacName: json['zodiacName'] as String? ?? '',
      applicableYears: List<String>.from(json['applicableYears'] as List? ?? []),
      overallLuck: json['overallLuck'] as String?,
      financialLuck: json['financialLuck'] as String?,
      loveLuck: json['loveLuck'] as String?,
      healthLuck: json['healthLuck'] as String?,
      luckyNumber: json['luckyNumber'] as int?,
      luckyColor: json['luckyColor'] as String?,
      advice: json['advice'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestDate': requestDate,
      'zodiacName': zodiacName,
      'applicableYears': applicableYears,
      'overallLuck': overallLuck,
      'financialLuck': financialLuck,
      'loveLuck': loveLuck,
      'healthLuck': healthLuck,
      'luckyNumber': luckyNumber,
      'luckyColor': luckyColor,
      'advice': advice,
    };
  }

  // 디버깅이나 로깅을 위한 toString 메서드 (선택 사항)
  @override
  String toString() {
    return 'ZodiacLuckData(zodiacName: $zodiacName, date: $requestDate, overall: $overallLuck)';
  }
}