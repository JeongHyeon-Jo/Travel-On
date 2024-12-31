import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:travel_on_final/features/chat/presentation/widgets/map_detail_widget.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:travel_on_final/features/map/presentation/providers/map_provider.dart';
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MapSearchScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const MapSearchScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _MapSearchScreenState createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapProvider _mapProvider = MapProvider();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final results = await _mapProvider.searchLocations(query);
      setState(() {
        _searchResults = results;
      });
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

  void _showMapDetailDialog(BuildContext context, TravelPoint location) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('장소 공유하기'),
          content: Container(
            padding: EdgeInsets.all(16.w),
            child: MapDetailWidget(location: location),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                _shareLocation(location);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('공유하기'),
            ),
          ],
        );
      },
    );
  }

  void _shareLocation(TravelPoint location) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.sendLocationMessage(
      chatId: widget.chatId,
      otherUserId: widget.otherUserId,
      context: context,
      title: location.name,
      address: location.address,
      latitude: location.location.latitude,
      longitude: location.location.longitude,
    );
  }

  PointType _determinePointType(String category) {
    if (category.contains('숙박')) return PointType.hotel;
    if (category.contains('음식')) return PointType.restaurant;
    return PointType.attraction;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('장소 검색')),
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
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      final title = place['title'].replaceAll(RegExp(r'<[^>]*>'), '');
                      final type = _determinePointType(place['category'] ?? '');

                      final location = TravelPoint(
                        id: UniqueKey().toString(),
                        name: title,
                        type: type,
                        location: NLatLng(
                          double.parse(place['mapy']) / 10000000,
                          double.parse(place['mapx']) / 10000000,
                        ),
                        address: place['address'] ?? '',
                        description: place['description'] ?? '',
                        order: index,
                        day: 1,
                      );

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
                          subtitle: Text(place['address'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(Icons.share, color: Colors.blue),
                            onPressed: () => _showMapDetailDialog(context, location),
                          ),
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
