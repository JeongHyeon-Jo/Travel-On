import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';

abstract class TravelRepository {
  Future<List<TravelPackage>> getPackages();
  Future<void> addPackage(TravelPackage package);
  Future<void> updatePackage(TravelPackage package);
  Future<void> deletePackage(String packageId);
  Future<void> toggleLike(String packageId, String userId);
  Future<List<String>> getLikedPackages(String userId);
}
