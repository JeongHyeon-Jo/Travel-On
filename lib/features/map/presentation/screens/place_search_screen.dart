import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

class PlaceSearchScreen extends StatefulWidget {
  final List<TravelPoint> selectedPoints;

  const PlaceSearchScreen({
    Key? key,
    required this.selectedPoints,
  }) : super(key: key);

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final uri = Uri.parse('https://openapi.naver.com/v1/search/local.json')
          .replace(queryParameters: {'query': query, 'display': '20'});

      final response = await http.get(
        uri,
        headers: {
          'X-Naver-Client-Id': 'GzfydSb1vlCZqce1VtJq',
          'X-Naver-Client-Secret': 'viquA27z93',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['items'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PointType _determinePointType(String category) {
    if (category.contains('숙박') || category.contains('호텔')) {
      return PointType.hotel;
    } else if (category.contains('음식') || category.contains('식당')) {
      return PointType.restaurant;
    } else {
      return PointType.attraction;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장소 검색'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '장소 이름으로 검색...',
                      hintStyle: TextStyle(color: Colors.blue, fontSize: 14.sp),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Colors.blue),
                  onPressed: () => _searchPlaces(_searchController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                final title = place['title'].toString().replaceAll(RegExp(r'<[^>]*>'), '');
                final type = _determinePointType(place['category'] ?? '');

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: ListTile(
                    leading: Icon(
                      type == PointType.hotel
                          ? Icons.hotel
                          : type == PointType.restaurant
                              ? Icons.restaurant
                              : Icons.photo_camera,
                    ),
                    title: Text(title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place['address'] ?? ''),
                        if (place['category'] != null)
                          Text(
                            place['category'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      final newPoint = TravelPoint(
                        id: UniqueKey().toString(),
                        name: title,
                        type: type,
                        location: NLatLng(
                          double.parse(place['mapy']) / 10000000,
                          double.parse(place['mapx']) / 10000000,
                        ),
                        address: place['address'] ?? '',
                        description: place['description'] ?? '',
                        order: widget.selectedPoints.length,
                        day: 1,
                      );

                      Navigator.pop(context, newPoint);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
