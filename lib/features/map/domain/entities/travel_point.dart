import 'package:flutter_naver_map/flutter_naver_map.dart';

enum PointType {
  hotel,
  restaurant,
  attraction
}

class TravelPoint {
  final String id;
  final String name;
  final PointType type;
  final NLatLng location;
  final String address;
  final String description;
  final int order;
  final int day;  // day 필드 추가

  TravelPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.address,
    required this.description,
    required this.order,
    required this.day,  // day 매개변수 추가
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
    'latitude': location.latitude,
    'longitude': location.longitude,
    'address': address,
    'description': description,
    'order': order,
    'day': day,  // day 추가
  };

  factory TravelPoint.fromJson(Map<String, dynamic> json) {
    return TravelPoint(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PointType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => PointType.attraction,
      ),
      location: NLatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      address: json['address'] as String,
      description: json['description'] as String,
      order: json['order'] as int,
      day: (json['day'] as int?) ?? 0,  // 기본값 설정
    );
  }

  // 복사본 생성 메서드 수정
  TravelPoint copyWith({
    String? id,
    String? name,
    PointType? type,
    NLatLng? location,
    String? address,
    String? description,
    int? order,
    int? day,  // day 매개변수 추가
  }) {
    return TravelPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      address: address ?? this.address,
      description: description ?? this.description,
      order: order ?? this.order,
      day: day ?? this.day,  // day 복사
    );
  }
}