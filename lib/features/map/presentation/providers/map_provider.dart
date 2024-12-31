import 'dart:convert';
import 'package:http/http.dart' as http;

class MapProvider {
  final String clientId = 'CLIENT_ID';
  final String clientSecret = 'CLIENT_SECRET';

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    final url = Uri.parse(
        'https://openapi.naver.com/v1/search/local.json?query=$query&display=5');

    final response = await http.get(
      url,
      headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['items'] as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('위치 정보를 불러오지 못했습니다. 상태 코드: ${response.statusCode}');
    }
  }
}
