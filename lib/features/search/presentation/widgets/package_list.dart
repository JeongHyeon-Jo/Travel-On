import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import '../../domain/entities/travel_package.dart';

// 패키지 목록 위젯
class PackageList extends StatelessWidget {
  const PackageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        final packages = provider.sortedPackages;
        if (packages.isEmpty) {
          return const Center(child: Text('등록된 패키지가 없습니다.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            return LikeablePackageCard(package: packages[index]);
          },
        );
      },
    );
  }
}

// 패키지 카드 위젯
class LikeablePackageCard extends StatefulWidget {
  final TravelPackage package;

  const LikeablePackageCard({
    super.key,
    required this.package,
  });

  @override
  State<LikeablePackageCard> createState() => _LikeablePackageCardState();
}

class _LikeablePackageCardState extends State<LikeablePackageCard> {
  final NumberFormat _priceFormat = NumberFormat('#,###');
  Stream<DocumentSnapshot>? packageStream;

  @override
  void initState() {
    super.initState();
    packageStream = FirebaseFirestore.instance
        .collection('packages')
        .doc(widget.package.id)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TravelProvider>(
      builder: (context, authProvider, travelProvider, _) {
        final userId = authProvider.currentUser?.id;
        final isLiked =
            userId != null && widget.package.likedBy.contains(userId);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 패키지 정보 부분
              InkWell(
                onTap: () {
                  context.push('/package-detail/${widget.package.id}',
                      extra: widget.package);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPackageImage(),
                    _buildPackageInfo(),
                  ],
                ),
              ),
              // 좋아요 버튼 부분
              _buildLikeButton(userId, isLiked),
            ],
          ),
        );
      },
    );
  }

  // 패키지 이미지 위젯
  Widget _buildPackageImage() {
    if (widget.package.mainImage != null &&
        widget.package.mainImage!.isNotEmpty) {
      return Image.network(
        widget.package.mainImage!,
        height: 200.h,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
    return _buildImagePlaceholder();
  }

  // 이미지 플레이스홀더 위젯
  Widget _buildImagePlaceholder() {
    return Container(
      height: 200.h,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.landscape,
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  // 패키지 정보 위젯
  Widget _buildPackageInfo() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.package.getTitle(context.locale.languageCode),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.package.getDescription(context.locale.languageCode),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Text(
            '₩${_priceFormat.format(widget.package.price.toInt())}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.travelonBlueColor,
            ),
          ),
        ],
      ),
    );
  }

  // 좋아요 버튼 위젯
  Widget _buildLikeButton(String? userId, bool isLiked) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey.shade900.withOpacity(0.9)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Consumer<TravelProvider>(
          // StreamBuilder 대신 Consumer 사용
          builder: (context, provider, _) {
            final package = provider.getPackageById(widget.package.id);
            if (package == null) return _buildLikeButtonPlaceholder();

            final isLiked = userId != null && package.likedBy.contains(userId);

            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _handleLikeButton(userId, context),
                ),
                // SizedBox(width: 4.w),
                Text(
                  '${package.likesCount}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
            );
          },
        ),
      ),
    );
  }

  // 좋아요 버튼 플레이스홀더
  Widget _buildLikeButtonPlaceholder() {
    return Row(
      children: [
        Text(
          '${widget.package.likesCount}',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 4.w),
        const Icon(Icons.favorite_border, color: Colors.grey),
      ],
    );
  }

  // 좋아요 버튼 핸들러
  Future<void> _handleLikeButton(String? userId, BuildContext context) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      context.push('/login');
      return;
    }

    try {
      final travelProvider = context.read<TravelProvider>();
      await travelProvider.toggleLikePackage(widget.package.id, userId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }
}
