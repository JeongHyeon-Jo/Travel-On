import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/tourism_density.dart';

class TourismDensityModel extends TourismDensity {
  TourismDensityModel({
    required super.name,
    required super.density,
    required super.location,
    required super.category,
  });

  factory TourismDensityModel.fromJson(Map<String, dynamic> json) {
    return TourismDensityModel(
      name: json['tAtsNm'] ?? '',
      density: double.parse(json['cnctrRate'] ?? '0'),
      location: json['location'] ?? json['areaNm'] ?? '',
      category: _determineCategory(json['tAtsNm'] ?? ''),
    );
  }

  static String _determineCategory(String name) {
    String category;
    if (name.contains('궁') || name.contains('문'))
      category = 'tourist_category.palace';
    else if (name.contains('해수욕장') || name.contains('해변'))
      category = 'tourist_category.beach';
    else if (name.contains('산') || name.contains('공원'))
      category = 'tourist_category.nature';
    else if (name.contains('타워') || name.contains('전망대'))
      category = 'tourist_category.observatory';
    else
      category = 'tourist_category.attraction';

    print('Category Key: $category'); // 디버깅 출력
    return category.tr(); // 여기서 번역을 수행
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'density': density,
      'location': location,
      'category': category,
    };
  }
}