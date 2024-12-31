import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../search/presentation/providers/travel_provider.dart';

class PackageTag extends StatelessWidget {
  final String packageId;
  final String packageTitle;

  const PackageTag({
    super.key,
    required this.packageId,
    required this.packageTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () async {
          try {
            final exists = await context
                .read<TravelProvider>()
                .checkPackageExists(packageId);

            if (!exists) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('common.notice'.tr()),
                    content: const Text('존재하지 않거나 종료된 패키지입니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }

            if (context.mounted) {
              context.push('/package/$packageId');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('패키지 정보를 불러올 수 없습니다')),
              );
            }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer,
                size: 16.sp,
                color: Colors.blue,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  packageTitle,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
