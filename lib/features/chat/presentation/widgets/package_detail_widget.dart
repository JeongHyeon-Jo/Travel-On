import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PackageDetailWidget extends StatelessWidget {
  final TravelPackage package;

  const PackageDetailWidget({Key? key, required this.package}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: package.mainImage ?? '',
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/default_image.png',
                width: 250.w,
                height: 250.h,
                fit: BoxFit.cover,
              ),
              width: 250.w,
              height: 250.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            package.title,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text('가격: ${package.price}원', style: TextStyle(fontSize: 16.sp, color: Colors.blue)),
          Text('가이드: ${package.guideName}', style: TextStyle(fontSize: 14.sp, color: Colors.black)),
          SizedBox(height: 8.h),
          Text(
            package.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size(100.w, 36.h),
            ),
            child: Text(
              '패키지 상세 정보 보기',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
