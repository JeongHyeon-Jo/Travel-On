import 'package:equatable/equatable.dart';

class RegionalSpot extends Equatable {
  final String name;
  final String address;
  final String category;
  final int rank;
  final String cityCode;
  final String districtCode;
  final String baseMonth;

  const RegionalSpot({
    required this.name,
    required this.address,
    required this.category,
    required this.rank,
    required this.cityCode,
    required this.districtCode,
    required this.baseMonth,
  });

  @override
  List<Object?> get props => [
        name,
        address,
        category,
        rank,
        cityCode,
        districtCode,
        baseMonth,
      ];
}
