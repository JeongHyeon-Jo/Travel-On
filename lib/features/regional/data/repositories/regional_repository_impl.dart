import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/regional_spot_model.dart';
import '../../domain/repositories/regional_repository.dart';
import '../../domain/entities/regional_spot.dart';
import '../../../../core/error/failures.dart';
import 'package:intl/intl.dart';

class RegionalRepositoryImpl implements RegionalRepository {
  final http.Client client;

  RegionalRepositoryImpl({required this.client});

  @override
  Future<List<RegionalSpot>> getRegionalSpots({
    required String cityCode,
    required String districtCode,
    String? category,
  }) async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final baseYm = DateFormat('yyyyMM').format(lastMonth);

      print('Requesting data for: $baseYm');

      final apiKey = dotenv.env['TOURISMDENSITY_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw ServerFailure('API 키가 설정되지 않았습니다.');
      }

      final queryParameters = {
        'serviceKey': apiKey,
        'numOfRows': '100',
        'pageNo': '1',
        'MobileOS': 'AND',
        'MobileApp': 'TravelOn',
        '_type': 'json',
        'baseYm': baseYm,
      };

      if (cityCode != 'all') {
        queryParameters['areaCd'] = cityCode;
        if (districtCode.isNotEmpty) {
          queryParameters['signguCd'] = districtCode;
        }
      }

      final uri = Uri.https(
        'apis.data.go.kr',
        '/B551011/TarRlteTarService/areaBasedList',
        queryParameters,
      );

      print('Request URL: $uri');

      final response = await client.get(
        uri,
        headers: {'Accept-Charset': 'UTF-8'},
      );

      final decodedBody = utf8.decode(response.bodyBytes);
      print('Response status code: ${response.statusCode}');
      print('Response body: $decodedBody');

      if (response.statusCode == 200) {
        if (decodedBody.trim().startsWith('<')) {
          // XML 에러 응답 처리
          if (decodedBody.contains('SERVICE_KEY_IS_NOT_REGISTERED_ERROR')) {
            throw ServerFailure('API 키가 유효하지 않습니다. API 키를 확인해주세요.');
          }
          throw ServerFailure('서버에서 XML 응답이 반환되었습니다.');
        }

        try {
          final data = json.decode(decodedBody);
          if (data['response']?['header']?['resultCode'] == '0000') {
            final items = data['response']?['body']?['items'];

            // items가 빈 문자열이거나 null이면 빈 리스트 반환
            if (items == null || items == '' || items is String) {
              print('No items found in response');
              return [];
            }

            // items.item이 있는 경우에만 처리
            final itemList = items['item'];
            if (itemList == null) {
              print('No item list found in items');
              return [];
            }

            // itemList가 List인 경우
            if (itemList is List) {
              var spots = itemList
                  .map((item) => RegionalSpotModel.fromJson(item))
                  .toList();

              if (category != null && category != '전체') {
                spots = spots.where((spot) {
                  return spot.category == category;
                }).toList();
              }

              return spots;
            }
            // itemList가 단일 객체인 경우
            else if (itemList is Map<String, dynamic>) {
              final spot = RegionalSpotModel.fromJson(itemList);
              if (category == null ||
                  category == '전체' ||
                  spot.category == category) {
                return [spot];
              }
            }

            return [];
          }
          throw ServerFailure('API 응답이 올바르지 않습니다.');
        } catch (e) {
          print('Error parsing response: $e');
          throw ServerFailure('응답 데이터 처리 중 오류가 발생했습니다: $e');
        }
      }
      throw ServerFailure('서버 응답 오류: ${response.statusCode}');
    } catch (e) {
      print('Error details: $e');
      if (e is ServerFailure) {
        rethrow;
      }
      throw ServerFailure(e.toString());
    }
  }
}
