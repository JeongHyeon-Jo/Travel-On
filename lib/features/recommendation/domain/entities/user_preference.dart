class UserPreference {
  final String userId;
  final List<String> likedPackages;
  final List<String> visitedRegions;
  final double averageSpending;
  final List<String> preferredCategories;
  final Map<String, double> regionScores;

  UserPreference({
    required this.userId,
    required this.likedPackages,
    required this.visitedRegions,
    required this.averageSpending,
    required this.preferredCategories,
    required this.regionScores,
  });
}
