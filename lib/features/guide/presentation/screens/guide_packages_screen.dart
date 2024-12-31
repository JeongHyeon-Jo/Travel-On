import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';

class GuidePackagesScreen extends StatefulWidget {
  final String guideId;
  final String guideName;

  const GuidePackagesScreen({
    Key? key,
    required this.guideId,
    required this.guideName,
  }) : super(key: key);

  @override
  State<GuidePackagesScreen> createState() => _GuidePackagesScreenState();
}

class _GuidePackagesScreenState extends State<GuidePackagesScreen> {
  @override
  void initState() {
    super.initState();
    // 빌드 완료 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackages();
    });
  }

  Future<void> _loadPackages() async {
    if (!mounted) return;
    await context.read<TravelProvider>().loadPackages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.guideName}님의 패키지'),
      ),
      body: Consumer<TravelProvider>(
        builder: (context, provider, _) {
          // 현재 가이드의 패키지만 필터링
          final guidePackages = provider.packages
              .where((package) => package.guideId == widget.guideId)
              .toList();

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (guidePackages.isEmpty) {
            return const Center(
              child: Text('등록된 패키지가 없습니다.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPackages,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: guidePackages.length,
              itemBuilder: (context, index) {
                final package = guidePackages[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: InkWell(
                    onTap: () {
                      context.push('/package-detail/${package.id}',
                          extra: package);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 패키지 이미지
                        if (package.mainImage != null &&
                            package.mainImage!.isNotEmpty)
                          Image.network(
                            package.mainImage!,
                            height: 200.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200.h,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.landscape,
                                  size: 50.sp,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            height: 200.h,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.landscape,
                              size: 50.sp,
                              color: Colors.grey[400],
                            ),
                          ),

                        // 패키지 정보
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                package.title,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                package.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₩${NumberFormat('#,###').format(package.price.toInt())}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.favorite,
                                          color: Colors.red, size: 16.sp),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${package.likesCount}',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                '${package.minParticipants}~${package.maxParticipants}인',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
