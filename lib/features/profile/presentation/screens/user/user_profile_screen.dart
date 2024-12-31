import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/review/domain/entities/review.dart';
import 'package:travel_on_final/features/review/presentation/provider/review_provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/chat/domain/usecases/create_chat_id.dart';
import 'package:travel_on_final/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({required this.userId, super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Future<UserModel?>? userFuture;
  bool showName = true;
  bool showEditOptions = false;

  @override
  void initState() {
    super.initState();
    userFuture = context.read<AuthProvider>().getUserById(widget.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviewsForUser(widget.userId);
    });
  }

  void _onEditProfileButtonPressed() {
    showPasswordDialog(context);
  }

  Future<void> _pickBackgroundImage(
      UserModel user, AuthProvider authProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await authProvider.updateUserProfile(
        name: user.name,
        profileImageUrl: user.profileImageUrl,
        introduction: user.introduction,
        backgroundImageUrl: pickedFile.path,
      );

      setState(() {
        userFuture = authProvider.getUserById(widget.userId);
      });
    }
  }

  Future<void> _removeBackgroundImage(
      UserModel user, AuthProvider authProvider) async {
    try {
      await authProvider.updateUserProfile(
        name: user.name,
        gender: user.gender,
        birthDate: user.birthDate,
        profileImageUrl: user.profileImageUrl,
        backgroundImageUrl: null,
        introduction: user.introduction,
      );

      setState(() {
        userFuture = authProvider.getUserById(widget.userId);
      });
    } catch (e) {
      print('배경 이미지 제거 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('user_profile.background.remove_error'.tr())),
      );
    }
  }

  void _showRemoveBackgroundDialog(
      UserModel user, AuthProvider authProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('user_profile.background.remove_title'.tr()),
          content: Text('user_profile.background.remove_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('user_profile.background.no'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('user_profile.background.yes'.tr()),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _removeBackgroundImage(user, authProvider);
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('user_profile.background.change_title'.tr()),
          content: Text('user_profile.background.change_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('user_profile.background.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('user_profile.background.confirm'.tr()),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reviewProvider = context.watch<ReviewProvider>();
    final travelProvider = context.watch<TravelProvider>();
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final isCurrentUser = authProvider.currentUser?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: FutureBuilder<UserModel?>(
          future: userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${snapshot.data!.name} ",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    TextSpan(
                      text: 'user_profile.title.with_name'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Text(
                'user_profile.title.default'.tr(),
              );
            }
          },
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('user_profile.error'.tr()));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('user_profile.user_not_found'.tr()));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 330.h,
                      decoration: BoxDecoration(
                        color: user.backgroundImageUrl == null ||
                                user.backgroundImageUrl!.isEmpty
                            ? isDarkMode
                                ? Colors.blue.shade100
                                : Colors.lightBlue.shade100
                            : null,
                        image: user.backgroundImageUrl != null &&
                                user.backgroundImageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(user.backgroundImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: user.backgroundImageUrl != null &&
                              user.backgroundImageUrl!.isNotEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            )
                          : null,
                    ),
                    if (user.isGuide)
                      Positioned(
                        top: 20.h,
                        left: 20.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'user_profile.guide_badge'.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 30.h,
                      child: Column(
                        children: [
                          Container(
                            child: CircleAvatar(
                              radius: 70.r,
                              backgroundImage: user.profileImageUrl != null &&
                                      user.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(user.profileImageUrl!)
                                  : const AssetImage(
                                          'assets/images/default_profile.png')
                                      as ImageProvider,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showName = !showName;
                              });
                            },
                            child: Row(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    key: ValueKey<bool>(showName),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 5.h, horizontal: 10.w),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: SizedBox(
                                      height: 30.h,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          showName ? user.name : user.email,
                                          style: TextStyle(
                                            fontSize: showName ? 20.sp : 12.sp,
                                            fontWeight: showName
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5.h, horizontal: 10.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              user.introduction ??
                                  'user_profile.default_intro'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    if (isCurrentUser)
                      Positioned(
                        top: 20.h,
                        right: 20.w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 35.w,
                              height: 35.h,
                              margin: EdgeInsets.only(bottom: 5.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                    showEditOptions ? Icons.close : Icons.list,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    showEditOptions = !showEditOptions;
                                  });
                                },
                              ),
                            ),
                            if (showEditOptions) ...[
                              Container(
                                width: 35.w,
                                height: 35.h,
                                margin: EdgeInsets.only(bottom: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_note,
                                      color: Colors.white),
                                  onPressed: _onEditProfileButtonPressed,
                                ),
                              ),
                              Container(
                                width: 35.w,
                                height: 35.h,
                                margin: EdgeInsets.only(bottom: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  onPressed: () async {
                                    final shouldChange =
                                        await _showConfirmationDialog(context);
                                    if (shouldChange) {
                                      _pickBackgroundImage(user, authProvider);
                                    }
                                  },
                                ),
                              ),
                              Container(
                                width: 35.w,
                                height: 35.h,
                                margin: EdgeInsets.only(bottom: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  onPressed: () => _showRemoveBackgroundDialog(
                                      user, authProvider),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Positioned(
                        top: 20.h,
                        right: 20.w,
                        child: Container(
                          width: 35.w,
                          height: 35.h,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chat_bubble,
                                color: Colors.white),
                            onPressed: () {
                              final currentUserId =
                                  authProvider.currentUser?.id;
                              if (currentUserId != null) {
                                final chatId =
                                    CreateChatId().call(currentUserId, user.id);
                                context.push('/chat/$chatId');
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 15.h,
                ),
                if (user.isGuide) ...[
                  FutureBuilder<Map<String, dynamic>>(
                    future: context
                        .read<TravelProvider>()
                        .getGuideReviewStats(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                            "user_profile.guide_stats.review_error".tr());
                      } else if (!snapshot.hasData) {
                        return Text("user_profile.guide_stats.no_reviews".tr());
                      } else {
                        final reviewStats = snapshot.data!;
                        final totalReviews = reviewStats['totalReviews'] as int;
                        final averageRating =
                            reviewStats['averageRating'] as double;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'user_profile.guide_stats.average_rating'.tr(
                                  namedArgs: {
                                    'rating': averageRating.toStringAsFixed(1)
                                  }),
                              style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'review.stats.count'.tr(namedArgs: {
                                'count': totalReviews.toString()
                              }),
                              style: TextStyle(
                                  fontSize: 14.sp, color: Colors.grey),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                if (index < averageRating.floor()) {
                                  return Icon(Icons.star,
                                      color: Colors.amber, size: 24.w);
                                } else if (index < averageRating) {
                                  return Icon(Icons.star_half,
                                      color: Colors.amber, size: 24.w);
                                } else {
                                  return Icon(Icons.star_border,
                                      color: Colors.grey, size: 24.w);
                                }
                              }),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "user_profile.guide_stats.packages.title".tr(),
                        style: TextStyle(
                            fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/user-packages/${user.id}');
                        },
                        child: Text(
                          "user_profile.guide_stats.packages.view_more".tr(),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GridView.builder(
                      itemCount: travelProvider.packages
                          .where((package) => package.guideId == user.id)
                          .take(6)
                          .length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                      ),
                      itemBuilder: (context, index) {
                        final guidePackages = travelProvider.packages
                            .where((package) => package.guideId == user.id)
                            .toList();
                        final package = guidePackages[index];
                        final formattedPrice =
                            NumberFormat('#,###').format(package.price.toInt());
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Column(
                              children: [
                                Container(
                                  width: 100.w,
                                  height: 90.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: package.mainImage != null
                                        ? Image.network(
                                            package.mainImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/default_image.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  package.getTitle(context.locale.languageCode),
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '₩$formattedPrice',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "최근에 작성한 리뷰",
                        style: TextStyle(
                            fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/user-reviews/${user.id}');
                        },
                        child: const Text("더보기"),
                      ),
                    ],
                  ),
                  Selector<ReviewProvider, List<Review>>(
                    selector: (_, provider) =>
                        provider.userReviews.take(5).toList(),
                    builder: (context, userReviews, child) {
                      if (userReviews.isEmpty) {
                        return const Center(child: Text("작성한 리뷰가 없습니다."));
                      }

                      return ListView.builder(
                        itemCount: userReviews.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final review = userReviews[index];
                          final package = context
                              .read<TravelProvider>()
                              .packages
                              .firstWhere(
                                (pkg) => pkg.id == review.packageId,
                                orElse: () => null as dynamic,
                              );

                          return Card(
                            margin: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 16.w),
                            elevation: 3,
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...[
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
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "평점: ${review.rating} / 5",
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey),
                                      ),
                                      Text(
                                        "작성일: ${DateFormat('yyyy.MM.dd').format(review.createdAt)}",
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
