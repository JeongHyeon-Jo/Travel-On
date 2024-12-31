// lib/features/home/data/models/weather_model.dart
class WeatherModel {
  final String city;
  final double temperature;
  final String condition;
  final double windSpeed;
  final int humidity;
  final double precipitation; // 강수량

  WeatherModel({
    required this.city,
    required this.temperature,
    required this.condition,
    required this.windSpeed,
    required this.humidity,
    required this.precipitation,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // 기상청 API response 형식에 맞춰 파싱
    return WeatherModel(
      city: json['city'],
      temperature: double.parse(json['temp']),
      condition: _parseCondition(json['sky']), // 하늘상태(SKY) 코드 변환
      windSpeed: double.parse(json['wsd']),
      humidity: int.parse(json['reh']),
      precipitation: double.parse(json['rn1']),
    );
  }

  static String _parseCondition(String sky) {
    // 기상청 날씨 코드를 텍스트로 변환
    switch (sky) {
      case '1':
        return '맑음';
      case '3':
        return '구름많음';
      case '4':
        return '흐림';
      default:
        return '맑음';
    }
  }
}
