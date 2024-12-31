import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MapDetailScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String name;
  final String address;

  const MapDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
  });

  // 네이버 지도 검색 메서드
  Future<void> _openNaverMap(
      String name, String address, BuildContext context) async {
    String locationPrefix = '';
    if (address.isNotEmpty) {
      final addressParts = address.split(' ');
      if (addressParts.length >= 3) {
        locationPrefix =
            '${addressParts[0]} ${addressParts[1]} ${addressParts[2]} ';
      } else if (addressParts.length >= 2) {
        locationPrefix = '${addressParts[0]} ${addressParts[1]} ';
      }
    }

    final searchQuery = Uri.encodeComponent('$locationPrefix$name');
    final mapAppUrl =
        'nmap://search?query=$searchQuery&appname=com.example.travel_on_final';
    final mapWebUrl = 'https://map.naver.com/v5/search/$searchQuery';

    try {
      if (await canLaunchUrl(Uri.parse(mapAppUrl))) {
        await launchUrl(Uri.parse(mapAppUrl),
            mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(mapWebUrl))) {
        await launchUrl(Uri.parse(mapWebUrl),
            mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도를 열 수 없습니다.')),
        );
      }
    } catch (e) {
      print('Error launching map: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    late NaverMapController mapController;

    return Scaffold(
      appBar: AppBar(title: const Text('위치 상세')),
      body: Column(
        children: [
          SizedBox(
            height: 550.h,
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(latitude, longitude),
                  zoom: 16,
                ),
                mapType: NMapType.basic,
              ),
              onMapReady: (controller) {
                mapController = controller;
                mapController.addOverlay(NMarker(
                  id: 'detail-marker',
                  position: NLatLng(latitude, longitude),
                ));
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '위치 상세 정보',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => _openNaverMap(name, address, context),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 12.h, horizontal: 16.w),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 2.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/naver_square.png',
                            height: 24.w,
                            width: 24.w,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.sp,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.search,
                            size: 24.sp,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
