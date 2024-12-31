class NextTripEntity {
  final String packageTitle;      // 기본 제목 (한국어)
  final String? packageTitleEn;   // 영어 제목
  final String? packageTitleJa;   // 일본어 제목
  final String? packageTitleZh;   // 중국어 제목
  final DateTime tripDate;
  final int? dDay;
  final bool isTodayTrip;

  NextTripEntity({
    required this.packageTitle,
    this.packageTitleEn,
    this.packageTitleJa,
    this.packageTitleZh,
    required this.tripDate,
    this.dDay,
    required this.isTodayTrip,
  });

  // 선택사항: fromJson 팩토리 메서드 추가
  factory NextTripEntity.fromJson(Map<String, dynamic> json) {
    return NextTripEntity(
      packageTitle: json['packageTitle'] ?? '',
      packageTitleEn: json['packageTitleEn'],
      packageTitleJa: json['packageTitleJa'],
      packageTitleZh: json['packageTitleZh'],
      tripDate: (json['tripDate'] as DateTime),
      dDay: json['dDay'],
      isTodayTrip: json['isTodayTrip'] ?? false,
    );
  }
}