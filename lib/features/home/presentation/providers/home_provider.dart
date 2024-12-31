// lib/features/home/presentation/providers/home_provider.dart
import 'package:flutter/material.dart';
import '../../domain/entities/next_trip_entity.dart';
import '../../domain/usecases/get_next_trip.dart';

class HomeProvider extends ChangeNotifier {
  final GetNextTrip _getNextTrip;
  NextTripEntity? _nextTrip;
  bool _isLoading = false;

  HomeProvider(this._getNextTrip);

  NextTripEntity? get nextTrip => _nextTrip;
  bool get isLoading => _isLoading;

  Future<void> loadNextTrip(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _nextTrip = await _getNextTrip(userId);
    } catch (e) {
      _nextTrip = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
