import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class UserPackageScreen extends StatelessWidget {
  final String userId;

  const UserPackageScreen({required this.userId, super.key});

  Future<String> _fetchGuideName(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data()?['name'] ?? "가이드";
    } else {
      return "가이드";
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelProvider = context.watch<TravelProvider>();

    final userPackages = travelProvider.packages
        .where((package) => package.guideId == userId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: FutureBuilder<String>(
          future: _fetchGuideName(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("로딩 중...");
            } else if (snapshot.hasError) {
              return const Text("에러 발생");
            } else {
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${snapshot.data} ",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    TextSpan(
                      text: "님의 패키지 목록",
                      style: TextStyle(
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      body: userPackages.isEmpty
          ? const Center(
              child: Text("등록된 패키지가 없습니다."),
            )
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: userPackages.length,
                      itemBuilder: (context, index) {
                        final package = userPackages[index];
                        final formattedPrice =
                            NumberFormat('#,###').format(package.price.toInt());

                        return GestureDetector(
                          onTap: () {
                            context.push('/package/${package.id}');
                          },
                          child: Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: Image.network(
                                    package.mainImage ??
                                        'assets/images/default_image.png',
                                    width: double.infinity,
                                    height: 150.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        package.title,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        '₩$formattedPrice',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
            ),
    );
  }
}
