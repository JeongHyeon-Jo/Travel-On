import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tourism_density_model.dart';
import '../../../../core/constants/region_codes.dart';

class TourismDensityApi {
  static const baseUrl = 'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  // 환경변수에서 API 키 가져오기
  static String get apiKey => dotenv.env['TOURISMDENSITY_API_KEY'] ?? '';

  Future<List<TourismDensityModel>> getTourismDensity() async {
    try {
      List<TourismDensityModel> allSpots = [];

      for (var region in RegionCodes.regions) {
        final areaCode = RegionCodes.getAreaCode(region);
        final signguCode = RegionCodes.getSignguCode(
            region, RegionCodes.getDistricts(region).first);

        if (areaCode == null || signguCode == null) continue;

        final queryParams = {
          'serviceKey': apiKey,
          'numOfRows': '100',
          'pageNo': '1',
          'MobileOS': 'web',
          'MobileApp': 'travelOn',
          'areaCd': areaCode,
          'signguCd': signguCode,
        };

        final uri = Uri.parse('$baseUrl/tatsCnctrRatedList')
            .replace(queryParameters: queryParams);

        print('Requesting for $region: $uri');

        final response = await http.get(
          uri,
          headers: {'accept': '*/*'},
        );

        if (response.statusCode == 200) {
          final decodedBody = utf8.decode(response.bodyBytes);
          if (decodedBody.contains('<?xml')) {
            if (decodedBody.contains('<resultCode>0000</resultCode>')) {
              final spots = _parseXmlResponse(decodedBody, region);
              allSpots.addAll(spots);
            }
          }
        }
      }

      if (allSpots.isEmpty) {
        throw Exception('데이터를 찾을 수 없습니다');
      }

      return allSpots;
    } catch (e) {
      print('Exception occurred while fetching tourism density: $e');
      throw Exception('관광지 정보를 불러오는데 실패했습니다');
    }
  }

  List<TourismDensityModel> _parseXmlResponse(
      String xmlString, String location) {
    Map<String, Map<String, dynamic>> latestSpots = {};

    final itemRegExp = RegExp(r'<item>.*?</item>', dotAll: true);
    final items = itemRegExp.allMatches(xmlString);

    for (var item in items) {
      final itemXml = item.group(0)!;

      final nameMatch = RegExp(r'<tAtsNm>([^<]+)</tAtsNm>').firstMatch(itemXml);
      final rateMatch =
          RegExp(r'<cnctrRate>([^<]+)</cnctrRate>').firstMatch(itemXml);
      final dateMatch =
          RegExp(r'<baseYmd>([^<]+)</baseYmd>').firstMatch(itemXml);

      if (nameMatch != null && rateMatch != null && dateMatch != null) {
        final name = nameMatch.group(1)!;
        final rate = double.parse(rateMatch.group(1)!);
        final date = dateMatch.group(1)!;

        if (!latestSpots.containsKey(name) ||
            int.parse(date) > int.parse(latestSpots[name]!['date'])) {
          latestSpots[name] = {
            'date': date,
            'model': TourismDensityModel(
              name: name,
              density: rate,
              location: location,
              category: _determineCategory(name),
            ),
          };
        }
      }
    }

    return latestSpots.values
        .map((spot) => spot['model'] as TourismDensityModel)
        .toList();
  }

  static String _determineCategory(String name) {
    if (name.contains('궁') || name.contains('문')) return 'palace';
    if (name.contains('해수욕장') || name.contains('해변')) return 'beach';
    if (name.contains('산') || name.contains('공원')) return 'nature';
    if (name.contains('타워') || name.contains('전망대')) return 'observatory';
    return 'attraction';
  }
}
