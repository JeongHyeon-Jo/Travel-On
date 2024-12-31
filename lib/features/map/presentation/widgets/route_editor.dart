import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:travel_on_final/features/map/presentation/screens/place_search_screen.dart';

class RouteEditor extends StatefulWidget {
  final List<TravelPoint> points;
  final Function(List<TravelPoint>) onPointsChanged;
  final int totalDays;

  const RouteEditor({
    super.key,
    required this.points,
    required this.onPointsChanged,
    required this.totalDays,
  });

  @override
  State<RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<RouteEditor> {
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    final currentDayPoints = _getPointsByDay(_selectedDay);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      children: [
        // 일차 선택 탭
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.totalDays,
            itemBuilder: (context, index) {
              final day = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  backgroundColor: Colors.transparent,
                  checkmarkColor: Colors.white,
                  label: Text(
                    '$day일차',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : _selectedDay == day
                              ? Colors.white
                              : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selectedColor: AppColors.travelonBlueColor,
                  selected: _selectedDay == day,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDay = day;
                      });
                    }
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 장소 추가 버튼들
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.hotel),
              label: const Text('숙소'),
              onPressed: () => _addPoint(PointType.hotel),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restaurant),
              label: const Text('식당'),
              onPressed: () => _addPoint(PointType.restaurant),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('관광지'),
              onPressed: () => _addPoint(PointType.attraction),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 선택된 일차의 장소 목록
        Expanded(
          child: ListView.builder(
            itemCount: currentDayPoints.length, // 현재 일차의 장소만
            itemBuilder: (context, index) {
              final point = currentDayPoints[index]; // 현재 일차의 장소
              return ListTile(
                leading: Icon(
                  point.type == PointType.hotel
                      ? Icons.hotel
                      : point.type == PointType.restaurant
                          ? Icons.restaurant
                          : Icons.photo_camera,
                  color: Colors.blue,
                ),
                title: Text('${index + 1}. ${point.name}'),
                subtitle: Text(point.address),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      widget.points.removeWhere((p) => p.id == point.id);
                      // 순서 재정렬
                      final dayPoints = _getPointsByDay(_selectedDay);
                      for (var i = 0; i < dayPoints.length; i++) {
                        final point = dayPoints[i];
                        final index =
                            widget.points.indexWhere((p) => p.id == point.id);
                        if (index != -1) {
                          widget.points[index] = point.copyWith(order: i);
                        }
                      }
                      widget.onPointsChanged(widget.points);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 해당 일차의 포인트들만 필터링
  List<TravelPoint> _getPointsByDay(int day) {
    return widget.points.where((point) => point.day == day).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // 새로운 장소 추가
  Future<void> _addPoint(PointType type) async {
    final result = await Navigator.push<TravelPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceSearchScreen(
          selectedPoints: _getPointsByDay(_selectedDay),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // 현재 선택된 일차의 마지막 순서 구하기
        final currentDayPoints = _getPointsByDay(_selectedDay);
        final lastOrder = currentDayPoints.isEmpty
            ? 0
            : currentDayPoints.map((p) => p.order).reduce(max) + 1;

        // 새로운 포인트 추가
        widget.points.add(result.copyWith(
          day: _selectedDay,
          order: lastOrder,
        ));
        widget.onPointsChanged(widget.points);
      });
    }
  }
}
