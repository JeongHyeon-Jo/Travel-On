class GuideRanking {
  final String guideId;
  final String guideName;
  final String? profileImageUrl;
  final int totalReservations;
  final int packageCount;
  final double rating;

  GuideRanking({
    required this.guideId,
    required this.guideName,
    this.profileImageUrl,
    required this.totalReservations,
    required this.packageCount,
    required this.rating,
  });
}