import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/regional_spot.dart';

class RegionalSpotCard extends StatelessWidget {
  final RegionalSpot spot;

  const RegionalSpotCard({
    super.key,
    required this.spot,
  });

  void _openNaverMap(String name, String address) async {
    // 주소에서 시/군/구 정보 추출
    String locationPrefix = '';
    if (address.isNotEmpty) {
      final addressParts = address.split(' ');
      if (addressParts.length >= 3) {
        // 시/도 + 시 + 구 형태로 검색 (예: "경기 수원시 권선구")
        locationPrefix =
            '${addressParts[0]} ${addressParts[1]} ${addressParts[2]} ';
      } else if (addressParts.length >= 2) {
        // 시/도 + 시/군 형태로 검색
        locationPrefix = '${addressParts[0]} ${addressParts[1]} ';
      }
    }

    final searchQuery = Uri.encodeComponent('$locationPrefix$name');
    final url =
        'nmap://search?query=$searchQuery&appname=com.example.travel_on_final';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        final webUrl = 'https://map.naver.com/v5/search/$searchQuery';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl));
        } else {
          throw '지도를 열 수 없습니다.';
        }
      }
    } catch (e) {
      print('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      child: ListTile(
        title: Text(
          spot.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(spot.address),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.category,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '연관도 ${spot.rank}위',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(CupertinoIcons.placemark_fill, color: Colors.blue),
          onPressed: () => _openNaverMap(spot.name, spot.address),
        ),
        onTap: () => _openNaverMap(spot.name, spot.address),
      ),
    );
  }
}
