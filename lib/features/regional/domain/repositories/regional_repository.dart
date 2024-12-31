import '../entities/regional_spot.dart';

abstract class RegionalRepository {
  Future<List<RegionalSpot>> getRegionalSpots({
    required String cityCode,
    required String districtCode,
    String? category,
  });
}
