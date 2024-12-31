import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/review/domain/entities/review.dart';
import 'package:travel_on_final/features/review/presentation/provider/review_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';

class UserReviewScreen extends StatelessWidget {
  final String userId;

  const UserReviewScreen({required this.userId, Key? key}) : super(key: key);

  Future<String> _fetchUserName(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final user = await authProvider.getUserById(userId);
    return user?.name ?? "알 수 없는 사용자";
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.read<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _fetchUserName(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("이름을 찾는 중...");
            } else if (snapshot.hasError) {
              return Text("오류 발생");
            } else {
              return RichText(
                text: TextSpan(
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
                      text: "님이 작성한 리뷰",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      body: FutureBuilder<List<Review>>(
        future: reviewProvider.loadReviewsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("리뷰 데이터를 불러오는 중 오류가 발생했습니다."),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("작성한 리뷰가 없습니다."),
            );
          }

          final reviews = snapshot.data!;
          final travelProvider = context.watch<TravelProvider>();

          return ListView.builder(
            itemCount: reviews.length,
            padding: EdgeInsets.all(16.w),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final package = travelProvider.packages.firstWhere(
                (pkg) => pkg.id == review.packageId,
                orElse: () => null as dynamic,
              );
              final formattedDate = DateFormat('yyyy.MM.dd').format(review.createdAt);

              return GestureDetector(
                onTap: () async {
                  if (package != null) {
                    await context.push('/package/${package.id}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("패키지 정보를 찾을 수 없습니다."),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (package != null) ...[
                          Text(
                            "패키지: ${package.title}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],
                        Text(
                          review.content,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "평점: ${review.rating} / 5",
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            ),
                            Text(
                              "작성일: $formattedDate",
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
