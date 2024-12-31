import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TravelCard extends StatelessWidget {
  final String location; // 위치
  final String title; // 제목
  final String imageUrl; // 이미지 URL
  final Color? tagBackgroundColor; // 태그 배경색
  final Color? tagTextColor; // 태그 텍스트 색상
  final VoidCallback? onTap;

  const TravelCard({
    super.key,
    required this.location,
    required this.title,
    required this.imageUrl,
    this.tagBackgroundColor = Colors.blue,
    this.tagTextColor = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationTag(),
              SizedBox(height: 8.h),
              _buildTitle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTag() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // 하늘색 배경
        borderRadius: BorderRadius.circular(20.r), // 더 둥근 모서리
      ),
      child: Text(
        location,
        style: TextStyle(
          color: Colors.blue, // 파란색 텍스트
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
