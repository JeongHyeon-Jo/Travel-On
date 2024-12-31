import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../search/domain/entities/travel_package.dart';

class RecommendationCard extends StatelessWidget {
  final TravelPackage package;
  final int rank;

  const RecommendationCard({
    super.key,
    required this.package,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => context.push('/package-detail/${package.id}', extra: package),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (package.mainImage != null && package.mainImage!.isNotEmpty)
                  Image.network(
                    package.mainImage!,
                    width: double.infinity,
                    height: 200.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200.h,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200.h,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      // 기존 코드
                      // 'recommendation.rank'.tr(args: [rank.toString()]),

                      // 수정된 코드
                      context.locale.languageCode == 'ko'
                          ? '$rank위'
                          : context.locale.languageCode == 'en'
                          ? 'Rank $rank'
                          : context.locale.languageCode == 'ja'
                          ? '第${rank}位'
                          : '第${rank}名',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.getTitle(context.locale.languageCode),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    package.getDescription(context.locale.languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        package.averageRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(width: 16.w),
                      Icon(Icons.favorite, color: Colors.red, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        package.likesCount.toString(),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}