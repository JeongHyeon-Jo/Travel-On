// lib/features/home/domain/usecases/get_next_trip.dart
import '../entities/next_trip_entity.dart';
import '../repositories/home_repository.dart';

class GetNextTrip {
  final HomeRepository repository;

  GetNextTrip(this.repository);

  Future<NextTripEntity?> call(String userId) {
    return repository.getNextTrip(userId);
  }
}
