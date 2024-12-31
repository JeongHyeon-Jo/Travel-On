import 'package:flutter/material.dart';
import '../../domain/repositories/regional_repository.dart';
import '../../domain/entities/regional_spot.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/region_codes.dart';

class RegionalProvider extends ChangeNotifier {
  final RegionalRepository repository;

  RegionalProvider(this.repository);

  List<RegionalSpot> _spots = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCity;
  String? _selectedDistrict;
  String _selectedCategory = '전체';

  // Getters
  List<RegionalSpot> get spots => _spots;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCity => _selectedCity;
  String? get selectedDistrict => _selectedDistrict;
  String get selectedCategory => _selectedCategory;

  // 시/도 선택
  void setCity(String? city) {
    _selectedCity = city;
    _selectedDistrict = null;
    _spots = [];

    // 전체 선택시 바로 데이터 fetch
    if (city == '전체') {
      fetchRegionalSpots();
    }
    notifyListeners();
  }

  // 시/군/구 선택
  void setDistrict(String? district) {
    _selectedDistrict = district;
    if (district != null) {
      fetchRegionalSpots();
    }
    notifyListeners();
  }

  // 카테고리 선택
  void setCategory(String category) {
    _selectedCategory = category;
    if (_selectedCity != null && _selectedDistrict != null) {
      fetchRegionalSpots();
    }
    notifyListeners();
  }

  // 데이터 fetch
  Future<void> fetchRegionalSpots() async {
    if (_selectedCity == null || _selectedDistrict == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final spots = await repository.getRegionalSpots(
        cityCode: getCityCode(_selectedCity!),
        districtCode: getDistrictCode(_selectedDistrict!),
        category: _selectedCategory == '전체' ? null : _selectedCategory,
      );

      _spots = spots;
      _error = null;
    } catch (e) {
      _error = e is ServerFailure ? e.message : '데이터를 불러오는데 실패했습니다.';
      _spots = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for codes
  String getCityCode(String city) {
    if (city == '전체') return 'all';
    return RegionCodes.getCityCode(city);
  }

  String getDistrictCode(String district) {
    if (_selectedCity == null) return '';
    final cityCode = getCityCode(_selectedCity!);
    return RegionCodes.getDistrictCode(cityCode, district);
  }
}
