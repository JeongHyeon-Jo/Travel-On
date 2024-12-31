// lib/features/home/data/datasources/weather_api.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:travel_on_final/features/home/data/models/weather_models.dart';

class WeatherApi {
  static const baseUrl =
      'http://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';

  // 환경변수에서 인코딩된 API 키 가져오기
  static String get apiKey => dotenv.env['WEATHER_API_KEY'] ?? '';

  static final cities = {
    'weather_regions.seoul'.tr(): {'nx': 60, 'ny': 127},
    'weather_regions.busan'.tr(): {'nx': 98, 'ny': 76},
    'weather_regions.daegu'.tr(): {'nx': 89, 'ny': 90},
    'weather_regions.incheon'.tr(): {'nx': 55, 'ny': 124},
    'weather_regions.gwangju'.tr(): {'nx': 58, 'ny': 74},
    'weather_regions.deajeon'.tr(): {'nx': 67, 'ny': 100},
    'weather_regions.ulsan'.tr(): {'nx': 102, 'ny': 84},
    'weather_regions.jeju'.tr(): {'nx': 52, 'ny': 38},
  };

  Future<List<WeatherModel>> getCurrentWeather() async {
    List<WeatherModel> weatherList = [];
    final now = DateTime.now();

    for (var city in cities.entries) {
      try {
        final queryParams = {
          'serviceKey': apiKey, // 인코딩된 상태의 키 그대로 사용
          'pageNo': '1',
          'numOfRows': '1000',
          'dataType': 'JSON',
          'base_date': _formatDate(now),
          'base_time': _formatTime(now),
          'nx': city.value['nx'].toString(),
          'ny': city.value['ny'].toString(),
        };

        final uri = Uri.parse('$baseUrl/getUltraSrtNcst')
            .replace(queryParameters: queryParams);

        // print('Request URL for ${city.key}: $uri');

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'];
          if (contentType != null && contentType.contains('xml')) {
            print('Received XML response for ${city.key}');
            continue; // XML 응답일 경우 처리를 건너뜀
          }

          final data = json.decode(response.body);
          weatherList.add(_parseWeatherData(data, city.key));
        } else {
          print('Error status code for ${city.key}: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching weather for ${city.key}: $e');
      }
    }

    return weatherList;
  }

  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    var hour = date.hour;
    if (date.minute < 45) {
      hour = hour - 1;
      if (hour < 0) hour = 23;
    }
    return '${hour.toString().padLeft(2, '0')}00';
  }

  WeatherModel _parseWeatherData(Map<String, dynamic> data, String cityName) {
    final items = data['response']['body']['items']['item'];
    Map<String, String> values = {};

    for (var item in items) {
      values[item['category']] = item['obsrValue'];
    }

    // PTY(강수형태)와 SKY(하늘상태) 모두 확인
    final condition = _getDetailedCondition(
        values['PTY'] ?? '0', // 강수형태
        values['SKY'] ?? '1' // 하늘상태
        );

    return WeatherModel(
      city: cityName,
      temperature: double.parse(values['T1H'] ?? '0'),
      condition: condition,
      windSpeed: double.parse(values['WSD'] ?? '0'),
      humidity: int.parse(values['REH'] ?? '0'),
      precipitation: double.parse(values['RN1'] ?? '0'),
    );
  }

  String _getDetailedCondition(String pty, String sky) {
    // 강수형태 체크
    switch (pty) {
      case '1':
        return 'home.weather.conditions.rain'.tr();
      case '2':
        return 'home.weather.conditions.rain_snow'.tr();
      case '3':
        return 'home.weather.conditions.snow'.tr();
      case '4':
        return 'home.weather.conditions.shower'.tr();
    }

    // 하늘상태 체크
    switch (sky) {
      case '1':
        return 'home.weather.conditions.clear'.tr();
      case '3':
        return 'home.weather.conditions.cloudy'.tr();
      case '4':
        return 'home.weather.conditions.overcast'.tr();
      default:
        return 'home.weather.conditions.clear'.tr();
    }
  }
}
