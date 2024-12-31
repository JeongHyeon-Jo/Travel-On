import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';

class NaverRouteMapScreen extends StatefulWidget {
  final List<TravelPoint> points;
  final int totalDays;

  const NaverRouteMapScreen({
    super.key,
    required this.points,
    required this.totalDays,
  });

  @override
  State<NaverRouteMapScreen> createState() => _NaverRouteMapScreenState();
}

class _NaverRouteMapScreenState extends State<NaverRouteMapScreen> {
  NaverMapController? _mapController;
  String totalDistance = '';
  String totalDuration = '';
  final List<NOverlay> _pathOverlays = [];

  final List<Color> dayColors = [
    Colors.blue, // 1일차
    Colors.red, // 2일차
    Colors.green, // 3일차
    Colors.purple, // 4일차
    Colors.orange, // 5일차
    Colors.brown, // 6일차
    Colors.teal, // 7일차
  ];

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      double kilometers = meters / 1000.0;
      return '${kilometers.toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  @override
  void dispose() {
    if (_mapController != null) {
      for (var overlay in _pathOverlays) {
        _mapController?.deleteOverlay(overlay as NOverlayInfo);
      }
      _mapController?.dispose();
    }
    super.dispose();
  }

  Future<void> _createRoute(NaverMapController controller) async {
    if (widget.points.length < 2) return;

    try {
      // 기존 경로 제거
      for (var overlay in _pathOverlays) {
        await controller.deleteOverlay(overlay as NOverlayInfo);
      }
      _pathOverlays.clear();

      int totalDistanceMeters = 0;
      int totalDurationSeconds = 0;

      // 일차별로 경로 생성
      for (int day = 1; day <= widget.totalDays; day++) {
        final dayPoints = widget.points.where((p) => p.day == day).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (dayPoints.length < 2) continue;

        for (var i = 0; i < dayPoints.length - 1; i++) {
          final start = dayPoints[i];
          final end = dayPoints[i + 1];

          final uri = Uri.parse(
                  'https://naveropenapi.apigw.ntruss.com/map-direction/v1/driving')
              .replace(queryParameters: {
            'start': '${start.location.longitude},${start.location.latitude}',
            'goal': '${end.location.longitude},${end.location.latitude}',
            'option': 'trafast',
          });

          final response = await http.get(
            uri,
            headers: {
              'X-NCP-APIGW-API-KEY-ID': 'X-NCP-APIGW-API-KEY-ID',
              'X-NCP-APIGW-API-KEY': 'X-NCP-APIGW-API-KEY',
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['route']?['trafast']?[0]?['path'] != null) {
              final path = data['route']['trafast'][0]['path'] as List;
              final coords = path
                  .map((point) => NLatLng(
                        (point[1] as num).toDouble(),
                        (point[0] as num).toDouble(),
                      ))
                  .toList();

              final pathOverlay = NPathOverlay(
                id: 'path_${day}_$i',
                coords: coords,
                color: dayColors[(day - 1) % dayColors.length],
                width: 5,
                outlineColor: Colors.white,
                patternInterval: 0,
              );

              await controller.addOverlay(pathOverlay);
              _pathOverlays.add(pathOverlay);

              // 거리와 시간 정보 누적
              final summary = data['route']['trafast'][0]['summary'];
              totalDistanceMeters += summary['distance'] as int;
              totalDurationSeconds += summary['duration'] as int;
            }
          }
        }
      }

      setState(() {
        totalDistance = _formatDistance(totalDistanceMeters);
        totalDuration = _formatDuration(totalDurationSeconds);
      });
    } catch (e) {
      print('Error creating route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('경로 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  NLatLngBounds _calculateBounds(List<TravelPoint> points) {
    if (points.isEmpty) {
      return const NLatLngBounds(
        southWest: NLatLng(33.0, 124.0),
        northEast: NLatLng(38.0, 132.0),
      );
    }

    double minLat = points[0].location.latitude;
    double maxLat = points[0].location.latitude;
    double minLng = points[0].location.longitude;
    double maxLng = points[0].location.longitude;

    for (var point in points) {
      if (point.location.latitude < minLat) minLat = point.location.latitude;
      if (point.location.latitude > maxLat) maxLat = point.location.latitude;
      if (point.location.longitude < minLng) minLng = point.location.longitude;
      if (point.location.longitude > maxLng) maxLng = point.location.longitude;
    }

    return NLatLngBounds(
      southWest: NLatLng(minLat - 0.01, minLng - 0.01),
      northEast: NLatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  Widget _buildRouteLegend() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int day = 1; day <= widget.totalDays; day++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 3,
                      color: dayColors[(day - 1) % dayColors.length],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$day일차',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 코스'),
        actions: [
          if (totalDistance.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Text(
                  //   '총 거리: $totalDistance',
                  //   style: TextStyle(fontSize: 12),
                  // ),
                  // Text(
                  //   '예상 시간: $totalDuration',
                  //   style: TextStyle(fontSize: 12),
                  // ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: widget.points.isNotEmpty
                    ? widget.points.first.location
                    : const NLatLng(37.5666102, 126.9783881),
                zoom: 12,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onMapReady: (NaverMapController controller) async {
              setState(() {
                _mapController = controller;
              });

              for (var i = 0; i < widget.points.length; i++) {
                final point = widget.points[i];
                final marker = NMarker(
                  id: 'marker_${point.id}',
                  position: point.location,
                );

                marker.setCaption(
                  NOverlayCaption(
                    text: '${i + 1}. ${point.name}',
                    textSize: 14,
                    color: Colors.blue,
                    haloColor: Colors.white,
                  ),
                );

                await controller.addOverlay(marker);
              }

              if (widget.points.length > 1) {
                await _createRoute(controller);
              }

              if (widget.points.isNotEmpty) {
                final bounds = _calculateBounds(widget.points);
                await controller.updateCamera(
                  NCameraUpdate.fitBounds(
                    bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                );
              }
            },
          ),
          _buildRouteLegend(),
        ],
      ),
    );
  }
}
