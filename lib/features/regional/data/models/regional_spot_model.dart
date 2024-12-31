import '../../domain/entities/regional_spot.dart';

class RegionalSpotModel extends RegionalSpot {
  const RegionalSpotModel({
    required super.name,
    required super.address,
    required super.category,
    required super.rank,
    required super.cityCode,
    required super.districtCode,
    required super.baseMonth,
  });

  factory RegionalSpotModel.fromJson(Map<String, dynamic> json) {
    try {
      // 디버그용 로그
      print('Parsing spot data: $json');

      return RegionalSpotModel(
        name: json['rlteTatsNm']?.toString() ?? '',
        address: json['rlteBsicAdres']?.toString() ?? '',
        category: json['rlteCtgryLclsNm']?.toString() ?? '',
        rank: int.tryParse(json['rlteRank']?.toString() ?? '0') ?? 0,
        cityCode: json['areaCd']?.toString() ?? '',
        districtCode: json['signguCd']?.toString() ?? '',
        baseMonth: json['baseYm']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing RegionalSpotModel: $e');
      // 파싱 실패시 기본값으로 생성
      return const RegionalSpotModel(
        name: '',
        address: '',
        category: '',
        rank: 0,
        cityCode: '',
        districtCode: '',
        baseMonth: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rlteTatsNm': name,
      'rlteBsicAdres': address,
      'rlteCtgryLclsNm': category,
      'rlteRank': rank.toString(),
      'areaCd': cityCode,
      'signguCd': districtCode,
      'baseYm': baseMonth,
    };
  }
}
