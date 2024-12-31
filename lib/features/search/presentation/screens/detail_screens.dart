import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import '../widgets/package_list.dart';
import '../widgets/region_filter.dart';
import '../providers/travel_provider.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  String _getRegionText(String region) {
    return 'regions.$region'.tr();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().loadPackages();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색 모드 시작
  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  // 검색 모드 종료
  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      context.read<TravelProvider>().clearSearch();
    });
  }

  // 검색창 위젯
  Widget _buildSearchField() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'search.hint'.tr(),
        border: InputBorder.none,
        hintStyle:
            TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[400]),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            _searchController.clear();
            context.read<TravelProvider>().clearSearch();
          },
        ),
      ),
      style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black, fontSize: 16.sp),
      onChanged: (query) {
        context.read<TravelProvider>().search(query);
      },
      textInputAction: TextInputAction.search,
    );
  }

  // AppBar 액션 버튼들
  List<Widget> _buildActions() {
    if (_isSearching) {
      return [];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
      Consumer<TravelProvider>(
        builder: (context, provider, child) => RegionFilter(
          onRegionChanged: (String region) {
            provider.filterByRegion(region);
          },
        ),
      ),
      SizedBox(width: 8.w),
    ];
  }

  // 검색 결과 카운트 위젯
  Widget _buildSearchInfo() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Consumer<TravelProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox.shrink();
        }

        if (_isSearching && _searchController.text.isNotEmpty) {
          final matchCount = provider.packages.length;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'search.result_count'
                      .tr(namedArgs: {'count': matchCount.toString()}),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (provider.selectedRegion != 'all')
                  Text(
                    'search.region'.tr(namedArgs: {
                      'region': _getRegionText(provider.selectedRegion)
                    }),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey,
                    ),
                  ),
              ],
            ),
          );
        }

        if (provider.selectedRegion != 'all') {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
            child: Text(
              'search.selected_region'.tr(namedArgs: {
                'region': _getRegionText(provider.selectedRegion)
              }),
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.grey[300] : Colors.grey,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // 메인 위젯 빌드
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDarkMode ? Colors.white : Colors.black),
                onPressed: _stopSearch,
              )
            : null,
        title: _isSearching
            ? _buildSearchField()
            : Text(
                'search.title'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
        actions: _buildActions(),
      ),
      body: Column(
        children: [
          _buildSortSelector(), // 정렬 선택기를 상단에 배치
          _buildSearchInfo(),
          const Expanded(
            child: PackageList(),
          ),
        ],
      ),
    );
  }

  String _getSortText(SortOption option) {
    switch (option) {
      case SortOption.latest:
        return 'sort.latest'.tr();
      case SortOption.priceHigh:
        return 'sort.price_high'.tr();
      case SortOption.priceLow:
        return 'sort.price_low'.tr();
      case SortOption.popular:
        return 'sort.popular'.tr();
      case SortOption.highRating:
        return 'sort.high_rating'.tr();
      case SortOption.mostReviews:
        return 'sort.most_reviews'.tr();
      default:
        return 'sort.latest'.tr();
    }
  }

  Widget _buildSortSelector() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Consumer<TravelProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.r)),
                    ),
                    builder: (context) {
                      return Container(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text('sort.latest'
                                  .tr()
                                  .replaceAll('sort.', '')), // 'sort.' 제거
                              trailing: provider.currentSort ==
                                      SortOption.latest
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.latest);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text(
                                  'sort.popular'.tr().replaceAll('sort.', '')),
                              trailing: provider.currentSort ==
                                      SortOption.popular
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.popular);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text('sort.price_low'
                                  .tr()
                                  .replaceAll('sort.', '')),
                              trailing: provider.currentSort ==
                                      SortOption.priceLow
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.priceLow);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text('sort.price_high'
                                  .tr()
                                  .replaceAll('sort.', '')),
                              trailing: provider.currentSort ==
                                      SortOption.priceHigh
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.priceHigh);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text('sort.high_rating'
                                  .tr()
                                  .replaceAll('sort.', '')),
                              trailing: provider.currentSort ==
                                      SortOption.highRating
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.highRating);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: Text('sort.most_reviews'
                                  .tr()
                                  .replaceAll('sort.', '')),
                              trailing: provider.currentSort ==
                                      SortOption.mostReviews
                                  ? const Icon(Icons.check, color: Colors.blue)
                                  : null,
                              onTap: () {
                                provider.sortPackages(SortOption.mostReviews);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getSortText(provider.currentSort)
                            .replaceAll('sort.', ''),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white : Colors.black,
                          size: 20.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
