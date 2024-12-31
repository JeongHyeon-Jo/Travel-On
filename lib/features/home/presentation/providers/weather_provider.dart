// lib/features/home/presentation/providers/weather_provider.dart
import 'package:flutter/material.dart';
import 'package:travel_on_final/features/home/data/models/weather_models.dart';
import '../../data/datasources/weather_api.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherApi _weatherApi = WeatherApi();
  List<WeatherModel> _weatherList = [];
  bool _isLoading = false;
  String? _error;

  List<WeatherModel> get weatherList => _weatherList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWeather() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _weatherList = await _weatherApi.getCurrentWeather();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
