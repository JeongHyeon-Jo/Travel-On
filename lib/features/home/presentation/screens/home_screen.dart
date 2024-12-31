import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/home/presentation/providers/home_provider.dart';
import 'package:travel_on_final/features/home/presentation/widgets/next_trip_card.dart';
import 'package:travel_on_final/features/home/presentation/widgets/travel_card.dart';
import 'package:travel_on_final/features/home/presentation/widgets/weather_slider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/navigation_provider.dart';
import '../../../../features/notification/presentation/screens/notification_center_screen.dart';
import '../../../../features/notification/presentation/providers/notification_provider.dart';
import '../../../../features/home/presentation/widgets/tourism_density_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final travelProvider = context.read<TravelProvider>();

    if (authProvider.currentUser != null) {
      await context
          .read<HomeProvider>()
          .loadNextTrip(authProvider.currentUser!.id);
    }

    await travelProvider.loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: SizedBox(
          height: 40.h,
          child: Image.asset(
            'assets/images/travel_on_bg.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Travel On');
            },
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications,
                  color: Colors.amber[800],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationCenterScreen(),
                    ),
                  );
                },
              ),
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.unreadCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        provider.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NextTripCard(),
              SizedBox(height: 20.h),
              const WeatherSlider(),
              SizedBox(height: 10.h),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 15.w,
                crossAxisSpacing: 15.w,
                childAspectRatio: 0.9,
                children: [
                  _buildMenuItem(
                    CupertinoIcons.heart_fill,
                    'menu.travel_recommendation'.tr(),
                    '/recommendation',
                  ),
                  _buildMenuItem(
                    CupertinoIcons.person_3_fill,
                    'menu.guide_ranking'.tr(),
                    '/guide-ranking',
                  ),
                  _buildMenuItem(
                    CupertinoIcons.map_pin_ellipse,
                    'menu.local_tour'.tr(), // 키가 정확히 일치하는지 확인
                    '/regional-exploration',
                  ),
                  _buildMenuItem(
                    CupertinoIcons.camera_fill,
                    'menu.travel_gallery'.tr(),
                    '/travel-gallery',
                  ),
                ],
              ),
              // SizedBox(height: 10.h),
              const TourismDensityWidget(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home.popular_courses'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<NavigationProvider>().setIndex(1);
                    },
                    child: Row(
                      children: [
                        Text(
                          'common.see_more'.tr(), // 여기를 확인
                          style: const TextStyle(
                              color: AppColors.travelonBlueColor),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Consumer<TravelProvider>(
                builder: (context, provider, child) {
                  final popularPackages = provider.getPopularPackages();

                  return SizedBox(
                    height: 200.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularPackages.length,
                      itemBuilder: (context, index) {
                        final package = popularPackages[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: 16.w,
                            left: index == 0 ? 0 : 0,
                          ),
                          child: SizedBox(
                            width: 300.w,
                            child: TravelCard(
                              location: _getRegionText(package.region),
                              title: package.title,
                              imageUrl: package.mainImage ??
                                  'https://picsum.photos/300/200',
                              onTap: () {
                                context.push('/package-detail/${package.id}',
                                    extra: package);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, String route) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (route.isNotEmpty) {
              context.push(route);
            }
          },
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child:
                Icon(icon, color: AppColors.travelonLightBlueColor, size: 20.r),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
          maxLines: 2, // 1에서 2로 변경
          softWrap: true, // 자동 줄바꿈 활성화
        ),
      ],
    );
  }

  String _getRegionText(String region) {
    return 'regions.$region'.tr();
  }
}
