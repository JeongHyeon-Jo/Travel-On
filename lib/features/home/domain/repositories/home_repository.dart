// lib/features/home/domain/repositories/home_repository.dart
import '../entities/next_trip_entity.dart';

abstract class HomeRepository {
  Future<NextTripEntity?> getNextTrip(String userId);
}
