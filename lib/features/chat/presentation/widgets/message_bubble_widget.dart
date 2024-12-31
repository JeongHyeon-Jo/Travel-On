import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/features/chat/domain/entities/message_entity.dart';
import 'package:travel_on_final/features/chat/domain/usecases/create_chat_id.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final String otherUserName;
  final String currentUserId;
  final bool showTime;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    required this.currentUserId,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPackageMessage = message.sharedPackage != null;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: message.profileImageUrl != null &&
                            message.profileImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(message.profileImageUrl!)
                        : const AssetImage('assets/images/default_profile.png')
                            as ImageProvider,
                    radius: 15.r,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    otherUserName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              Container(
                constraints: BoxConstraints(
                  maxWidth: isPackageMessage
                      ? MediaQuery.of(context).size.width * 0.8
                      : MediaQuery.of(context).size.width * 0.6,
                ),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue.shade100 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                child: message.location != null
                    ? _buildLocationDetails(context, message.location!)
                    : isPackageMessage
                        ? _buildPackageDetails(context, message.sharedPackage!)
                        : (message.sharedUser != null
                            ? _buildUserDetails(context, message.sharedUser!)
                            : (message.imageUrl != null &&
                                    message.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: message.imageUrl!,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  )
                                : Text(
                                    message.text,
                                    style: TextStyle(
                                      color: isMe ? Colors.black : Colors.black,
                                      fontSize: 14.sp,
                                    ),
                                  ))),
              ),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(top: 0.h, right: 10.w, left: 10.w),
              child: Text(
                DateFormat('MM월 dd일 a hh:mm', 'ko')
                    .format(message.createdAt.toDate()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationDetails(
      BuildContext context, Map<String, dynamic> location) {
    final latitude = location['latitude'] ?? 0.0;
    final longitude = location['longitude'] ?? 0.0;
    final name = location['title'] ?? '위치 정보';
    final address = location['address'] ?? '';

    if (latitude == 0.0 && longitude == 0.0) {
      return const Center(child: Text('위치 정보를 불러올 수 없습니다.'));
    }

    late NaverMapController naverMapController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          key: ValueKey('${latitude}_$longitude'),
          width: 250.w,
          height: 150.h,
          child: RepaintBoundary(
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(latitude, longitude),
                  zoom: 16,
                ),
                mapType: NMapType.basic,
              ),
              onMapReady: (controller) {
                naverMapController = controller;
                naverMapController.addOverlay(NMarker(
                  id: 'shared-location',
                  position: NLatLng(latitude, longitude),
                ));
              },
            ),
          ),
        ),
        SizedBox(height: 8.h),
        ElevatedButton(
          onPressed: () {
            context.push(
              '/map-detail/$latitude/$longitude',
              extra: {
                'name': name,
                'address': address,
              },
            );
          },
          child: const Text('자세히 보기'),
        ),
      ],
    );
  }

  Widget _buildPackageDetails(
      BuildContext context, Map<String, dynamic> package) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final formattedPrice =
        NumberFormat('#,###').format(package['price'].toInt());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (package['mainImage'] != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: package['mainImage'] ?? '',
              placeholder: (context, url) => const CircularProgressIndicator(),
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
          package['title'] ?? '패키지 이름 없음',
          style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[800] : Colors.black),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: Text(
                '₩$formattedPrice',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: Text(
                '가이드',
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: Text(
                '${package['guideName']}',
                style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          package['description'] ?? '설명 없음',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey[800] : Colors.black),
        ),
        SizedBox(height: 16.h),
        Center(
          child: ElevatedButton(
            onPressed: () {
              try {
                final travelPackage = TravelPackage(
                  id: package['id'] as String? ?? '',
                  title: package['title'] as String? ?? '',
                  description: package['description'] as String? ?? '',
                  price: (package['price'] as num?)?.toDouble() ?? 0.0,
                  mainImage: package['mainImage'] as String?,
                  guideName: package['guideName'] as String? ?? '',
                  guideId: package['guideId'] as String? ?? '',
                  region: package['region'] as String? ?? '',
                  descriptionImages: package['descriptionImages'] is List
                      ? List<String>.from(package['descriptionImages'])
                      : [],
                  minParticipants: package['minParticipants'] as int? ?? 4,
                  maxParticipants: package['maxParticipants'] as int? ?? 8,
                  nights: package['nights'] as int? ?? 0,
                  departureDays: package['departureDays'] is List
                      ? List<int>.from(package['departureDays'])
                      : [],
                  likedBy: package['likedBy'] is List
                      ? List<String>.from(package['likedBy'])
                      : [],
                  likesCount: package['likesCount'] as int? ?? 0,
                  rating: (package['rating'] as num?)?.toDouble() ?? 0.0,
                  reviewCount: package['reviewCount'] as int? ?? 0,
                  totalDays: (package['totalDays'] as int?) ?? 1,
                  routePoints: package['routePoints'] is List
                      ? (package['routePoints'] as List)
                          .map((point) => TravelPoint.fromJson(
                              point as Map<String, dynamic>))
                          .toList()
                      : [],
                );

                context.push(
                  '/package-detail/${travelPackage.id}',
                  extra: travelPackage,
                );
              } catch (e) {
                print('패키지를 못 불러왔습니다.: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size(100.w, 36.h),
            ),
            child: Text(
              '패키지 상세 정보 보기',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetails(BuildContext context, Map<String, dynamic> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: user['profileImageUrl'] != null &&
                  user['profileImageUrl'].isNotEmpty
              ? CachedNetworkImageProvider(user['profileImageUrl'])
              : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
          radius: 30.r,
        ),
        SizedBox(height: 8.h),
        Text(
          user['name'] ?? '이름 없음',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(
          user['email'] ?? '이메일 없음',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        SizedBox(height: 8.h),
        Text(
          user['introduction'] ?? '소개 없음',
          style: TextStyle(fontSize: 14.sp),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                onPressed: () {
                  if (currentUserId.isNotEmpty &&
                      user['id'] is String &&
                      (user['id'] as String).isNotEmpty) {
                    final userId = user['id'] as String;
                    final chatId = CreateChatId().call(currentUserId, userId);
                    try {
                      Navigator.pop(context);
                      context.push('/chat/$chatId');
                    } catch (e) {
                      print('Navigation error: $e');
                    }
                  } else {
                    print('유효하지 않은 ID입니다.');
                  }
                },
                child: Text(
                  '1:1 채팅',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                ),
                onPressed: () {
                  if (user['id'] is String &&
                      (user['id'] as String).isNotEmpty) {
                    final userId = user['id'] as String;
                    context.push('/user-profile/${user['id']}');
                  } else {
                    print('유효하지 않은 ID입니다.');
                  }
                },
                child: Text(
                  '프로필 보기',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
