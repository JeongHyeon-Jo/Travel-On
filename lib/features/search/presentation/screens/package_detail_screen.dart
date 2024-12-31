import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:travel_on_final/features/map/presentation/screens/naver_route_map_screen.dart';
import 'package:travel_on_final/features/review/presentation/provider/review_provider.dart';
import 'package:travel_on_final/features/review/presentation/screens/review_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/travel_package.dart';
import 'package:travel_on_final/features/chat/domain/usecases/create_chat_id.dart';
import 'package:http/http.dart' as http;

class PackageDetailScreen extends StatefulWidget {
  final TravelPackage package;

  const PackageDetailScreen(
      {super.key, required this.package, required int totalDays});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final NumberFormat _priceFormat = NumberFormat('#,###');
  Future<int>? _todayParticipants;
  bool _isAvailable = true;
  final bool _showReviews = false;
  int _minParticipants = 0; // 기본값 설정
  int _maxParticipants = 0; // 기본값 설정
  String? _currentUserId;
  NaverMapController? _mapController;
  double _currentZoom = 8.0;
  final Map<String, NOverlayInfo> _pathOverlays = {}; // 추가

  Future<void> _createRouteOverlay(NaverMapController controller) async {
    try {
      // 기존 경로 제거
      for (var overlay in _pathOverlays.values) {
        await controller.deleteOverlay(overlay);
      }
      _pathOverlays.clear();

      // 일차별 색상 정의
      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.purple,
        Colors.orange,
      ];

      // 일차별로 경로 생성
      for (int day = 1; day <= widget.package.totalDays; day++) {
        final dayPoints = widget.package.routePoints
            .where((p) => p.day == day)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

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
              'X-NCP-APIGW-API-KEY-ID': 'j3gnaneqmd',
              'X-NCP-APIGW-API-KEY': 'WdWzIfcchu614fM1CD1vKA9JzaJATTj0DGKM5CPF',
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

              final pathOverlay =
                  NPathOverlay(id: 'path_${day}_$i', coords: coords);
              _pathOverlays['path_${day}_$i'] = pathOverlay as NOverlayInfo;
              await controller.addOverlay(pathOverlay);

              _pathOverlays['path_${day}_$i'] =
                  pathOverlay as NOverlayInfo; // Map에 저장
              await controller
                  .addOverlay(pathOverlay as NAddableOverlay<NOverlay<void>>);
            }
          }
        }
      }
    } catch (e) {
      print('Error creating route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('경로 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_mapController != null) {
      for (var overlay in _pathOverlays.values) {
        _mapController?.deleteOverlay(overlay);
      }
      _mapController?.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initState에서 값 설정
    _minParticipants = widget.package.minParticipants;
    _maxParticipants = widget.package.maxParticipants;
    _loadTodayParticipants();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReviewProvider>().loadPreviewReviews(widget.package.id);
      }
    });
  }

  Future<void> _loadTodayParticipants() async {
    setState(() {
      _todayParticipants = _getParticipantsForDate(DateTime.now());
    });
  }

  Future<int> _getParticipantsForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('packageId', isEqualTo: widget.package.id)
          .where('status', isEqualTo: 'approved')
          .where('reservationDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('reservationDate', isLessThan: Timestamp.fromDate(end))
          .get();

      if (mounted) {
        setState(() {
          _isAvailable = snapshot.docs.length < widget.package.maxParticipants;
        });
      }

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting participants: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text('package_detail.title'.tr()),
            surfaceTintColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메인 이미지
                if (widget.package.mainImage != null &&
                    widget.package.mainImage!.isNotEmpty)
                  Image.network(
                    widget.package.mainImage!,
                    height: 200.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200.h,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200.h,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    height: 200.h,
                    width: double.infinity,
                    color: Colors.blue.shade100,
                    child: Center(
                      child: Icon(
                        Icons.landscape,
                        size: 64,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목 및 지역
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.package
                                  .getTitle(context.locale.languageCode),
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getRegionText(widget.package.region),
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildReviewSection(), // 여기로 리뷰 섹션 이동

                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.person,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        onPressed: () {
                                          context.push(
                                              '/user-profile/${widget.package.guideId}');
                                        },
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0),
                                        ),
                                        onPressed: () {
                                          context.push(
                                              '/user-profile/${widget.package.guideId}');
                                        },
                                        child: Text(
                                          'package_detail.guide'.tr(namedArgs: {
                                            'name': widget.package.guideName
                                          }),
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_currentUserId !=
                                          widget.package.guideId)
                                        IconButton(
                                          onPressed: () async {
                                            final authProvider =
                                                Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false);
                                            final userId =
                                                authProvider.currentUser?.id;
                                            if (userId != null) {
                                              final otherUserId =
                                                  widget.package.guideId;
                                              final chatId = CreateChatId()
                                                  .call(userId, otherUserId);
                                              context.push('/chat/$chatId');
                                            }
                                          },
                                          icon: Icon(
                                            Icons.chat,
                                            color: isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.black,
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(width: 10.w),
                                Icon(
                                  Icons.group,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                SizedBox(width: 14.w),
                                Text(
                                  widget.package.maxParticipants != null
                                      ? 'package_detail.participants'
                                          .tr(namedArgs: {
                                          'min': widget.package.minParticipants
                                              .toString(),
                                          'max': widget.package.maxParticipants
                                              .toString(),
                                        })
                                      : 'package_detail.participants_unknown'
                                          .tr(),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                SizedBox(width: 48.h),
                                Text(
                                  'package_detail.price'.tr(namedArgs: {
                                    'price': _priceFormat
                                        .format(widget.package.price.toInt())
                                  }),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),

                      if (!_isAvailable)
                        Container(
                          margin: EdgeInsets.only(top: 8.w),
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.red),
                              SizedBox(width: 8.w),
                              Text(
                                'package_detail.booking_closed'.tr(),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 24.h),

                      // 설명
                      Text(
                        'package_detail.description'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.package
                            .getDescription(context.locale.languageCode),
                        style: TextStyle(
                          fontSize: 16.sp,
                          height: 1.5.h,
                        ),
                      ),

                      SizedBox(height: 24.h),
                      Text(
                        'package_detail.course'.tr(),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      if (widget.package.routePoints.isNotEmpty)
                        Container(
                          height: 300.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              NaverMap(
                                options: NaverMapViewOptions(
                                  initialCameraPosition: NCameraPosition(
                                    target: widget
                                        .package.routePoints.first.location,
                                    zoom: 8,
                                  ),
                                  scrollGesturesEnable: true,
                                  zoomGesturesEnable: true,
                                  rotationGesturesEnable: true,
                                  tiltGesturesEnable: true,
                                  stopGesturesEnable: true,
                                  locationButtonEnable: true,
                                  consumeSymbolTapEvents: false,
                                ),
                                onMapReady: (NaverMapController controller) {
                                  setState(() {
                                    _mapController = controller;
                                  });

                                  for (var i = 0;
                                      i < widget.package.routePoints.length;
                                      i++) {
                                    final point = widget.package.routePoints[i];
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

                                    controller.addOverlay(marker);
                                  }

                                  // 모든 포인트가 보이도록 카메라 위치 조정
                                  if (widget.package.routePoints.isNotEmpty) {
                                    final bounds = _calculateBounds(
                                        widget.package.routePoints);
                                    controller.updateCamera(
                                      NCameraUpdate.fitBounds(
                                        bounds,
                                        padding: const EdgeInsets.all(50),
                                      ),
                                    );
                                  }
                                },
                              ),
                              // 줌 컨트롤 버튼
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentZoom =
                                                    (_currentZoom + 1)
                                                        .clamp(1.0, 20.0);
                                                _mapController?.updateCamera(
                                                  NCameraUpdate.withParams(
                                                      zoom: _currentZoom),
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.black,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                            iconSize: 20,
                                          ),
                                          Container(
                                            height: 1,
                                            color: Colors.grey[300],
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _currentZoom =
                                                    (_currentZoom - 1)
                                                        .clamp(1.0, 20.0);
                                                _mapController?.updateCamera(
                                                  NCameraUpdate.withParams(
                                                      zoom: _currentZoom),
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.black,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                            iconSize: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 상세 경로 보기 버튼
                              Positioned(
                                bottom: 16,
                                left: 120,
                                right: 120,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NaverRouteMapScreen(
                                          points: widget.package.routePoints,
                                          totalDays: widget.package.totalDays,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('package_detail.view_route'.tr()),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          height: 100.h,
                          alignment: Alignment.center,
                          child: Text(
                            'package_detail.no_course'.tr(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16.sp,
                            ),
                          ),
                        ),

                      // 여행 코스 목록 표시
                      if (widget.package.routePoints.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.package.routePoints.length,
                          itemBuilder: (context, index) {
                            final point = widget.package.routePoints[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      point.type == PointType.hotel
                                          ? Icons.hotel
                                          : point.type == PointType.restaurant
                                              ? Icons.restaurant
                                              : Icons.photo_camera,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${index + 1}. ${point.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                subtitle: Text(
                                  point.address,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16.sp,
                                  color: Colors.grey,
                                ),
                                onTap: () => _showLocationInfo(point),
                              ),
                            );
                          },
                        ),
                      ],

                      SizedBox(height: 24.h),
                      // 설명 이미지들
                      if (widget.package.descriptionImages.isNotEmpty) ...[
                        SizedBox(height: 24.h),
                        Text(
                          'package_detail.images'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.package.descriptionImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.package.descriptionImages[index],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200.h,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200.h,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isAvailable
                  ? () => context.push('/reservation/${widget.package.id}',
                      extra: widget.package)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isAvailable
                    ? 'package_detail.booking.book_now'.tr()
                    : 'package_detail.booking.closed'.tr(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRegionText(String region) {
    return 'regions.$region'.tr();
  }

  Widget _buildReviewSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final totalReviewCount = reviewProvider.totalReviewCount;
        final totalAverageRating = reviewProvider.totalAverageRating;
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

        return TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewDetailScreen(
                  package: widget.package, // TravelPackage 전체를 전달
                ),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'review.count'
                    .tr(namedArgs: {'count': totalReviewCount.toString()}),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 20.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                totalAverageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        );
      },
    );
  }

  NLatLngBounds _calculateBounds(List<TravelPoint> points) {
    var minLat = points.first.location.latitude;
    var maxLat = points.first.location.latitude;
    var minLng = points.first.location.longitude;
    var maxLng = points.first.location.longitude;

    for (var point in points) {
      if (point.location.latitude < minLat) minLat = point.location.latitude;
      if (point.location.latitude > maxLat) maxLat = point.location.latitude;
      if (point.location.longitude < minLng) minLng = point.location.longitude;
      if (point.location.longitude > maxLng) maxLng = point.location.longitude;
    }

    return NLatLngBounds(
      southWest: NLatLng(minLat, minLng),
      northEast: NLatLng(maxLat, maxLng),
    );
  }

  void _showLocationInfo(TravelPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Map Preview
                    Container(
                      height: 200.h,
                      margin: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: NaverMap(
                          options: NaverMapViewOptions(
                            initialCameraPosition: NCameraPosition(
                              target: point.location,
                              zoom: 15,
                            ),
                            locationButtonEnable: true,
                          ),
                          onMapReady: (controller) {
                            controller.addOverlay(
                              NMarker(
                                id: 'detail_marker',
                                position: point.location,
                              )..setCaption(
                                  NOverlayCaption(
                                    text: point.name,
                                    textSize: 14,
                                    color: Colors.blue,
                                    haloColor: Colors.white,
                                  ),
                                ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Location Info
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with icon
                          Row(
                            children: [
                              Icon(
                                point.type == PointType.hotel
                                    ? Icons.hotel
                                    : point.type == PointType.restaurant
                                        ? Icons.restaurant
                                        : Icons.photo_camera,
                                color: Colors.blue,
                                size: 28.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  point.name,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Address
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    point.address,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (point.description.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'package_detail.location_info.details'.tr(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    point.description,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: 24.h),

                          // Open in Naver Map Button
                          ElevatedButton.icon(
                            onPressed: () => _openInNaverMap(point),
                            icon: const Icon(Icons.map),
                            label: Text(
                                'package_detail.location_info.view_map'.tr()),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 48.h),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInNaverMap(TravelPoint point) async {
    final webUrl =
        'https://map.naver.com/v5/search/${Uri.encodeComponent(point.name)}?c=${point.location.longitude},${point.location.latitude},15,0,0,0,dh';

    try {
      // 웹 URL을 바로 시도
      if (!await launchUrl(
        Uri.parse(webUrl),
        mode: LaunchMode.platformDefault,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('package_detail.location_info.map_error'.tr()),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('package_detail.location_info.map_error'.tr()),
          ),
        );
      }
    }
  }
}
