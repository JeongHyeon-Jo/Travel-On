import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserDetailWidget extends StatelessWidget {
  final UserModel user;

  const UserDetailWidget({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 40.r,
          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(
                  user.profileImageUrl!,
                )
              : AssetImage('assets/images/default_profile.png') as ImageProvider,
        ),
        SizedBox(height: 8.h),
        Text(user.name ?? '이름 없음', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        Text(user.email ?? '이메일 없음', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        Text(
          user.introduction ?? '소개 없음',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                minimumSize: Size(100.w, 36.h),
              ),
              child: Text(
                '1:1 채팅하기',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                minimumSize: Size(100.w, 36.h),
              ),
              child: Text(
                '프로필 보기',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
