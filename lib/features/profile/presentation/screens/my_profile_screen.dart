import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_dialogs.dart';
import '../widgets/theme_mode_switch.dart';
import '../../../../core/providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'profile.title'.tr(),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: ThemeModeSwitch(
              value: isDarkMode,
              onChanged: (bool value) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정보 카드
                  Card(
                    child: InkWell(
                      onTap: () => showPasswordDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  context.push('/user-profile/${user?.id}'),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: user?.profileImageUrl !=
                                            null &&
                                        user!.profileImageUrl!.isNotEmpty
                                    ? NetworkImage(user.profileImageUrl!)
                                    : const AssetImage(
                                            'assets/images/default_profile.png')
                                        as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'profile.default_user'.tr(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 가이드 기능 섹션
                  if (user?.isGuide == true) ...[
                    Text(
                      'profile.guide.section_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.add_box,
                                color: AppColors.travelonLightBlueColor),
                            title: Text('profile.guide.create_package'.tr()),
                            subtitle:
                                Text('profile.guide.create_package_desc'.tr()),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/add-package'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.calendar_today,
                                color: AppColors.travelonLightBlueColor),
                            title:
                                Text('profile.guide.manage_reservations'.tr()),
                            subtitle: Text(
                                'profile.guide.manage_reservations_desc'.tr()),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.travelonLightBlueColor),
                            onTap: () => context.push('/reservations/guide'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.list_alt,
                                color: AppColors.travelonLightBlueColor),
                            title: Text('profile.guide.manage_packages'.tr()),
                            subtitle:
                                Text('profile.guide.manage_packages_desc'.tr()),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.travelonLightBlueColor),
                            onTap: () => context.push('/my-packages'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 가이드 인증 메뉴
                  if (user?.isGuide != true) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_user,
                            color: AppColors.travelonLightBlueColor),
                        title: Text('profile.guide.certification'.tr()),
                        subtitle: Text('profile.guide.certification_desc'.tr()),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.travelonLightBlueColor),
                        onTap: () => context.push('/guide-certification'),
                      ),
                    ),
                  ],

                  // 예약 관리 섹션
                  const SizedBox(height: 24),
                  Text(
                    'profile.user.reservations_title'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bookmark,
                          color: AppColors.travelonLightBlueColor),
                      title: Text('profile.user.my_reservations'.tr()),
                      subtitle: Text('profile.user.my_reservations_desc'.tr()),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.travelonLightBlueColor),
                      onTap: () => context.push('/reservations/customer'),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.favorite,
                          color: AppColors.travelonLightBlueColor),
                      title: Text('profile.user.liked_packages'.tr()),
                      subtitle: Text('profile.user.liked_packages_desc'.tr()),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.travelonLightBlueColor),
                      onTap: () => context.push('/liked-packages'),
                    ),
                  ),

                  // 로그아웃 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          try {
                            await Provider.of<AuthProvider>(context,
                                    listen: false)
                                .logout(context);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              context.go('/login');
                            }
                          } catch (e) {
                            if (context.mounted) Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('로그아웃 실패: ${e.toString()}')),
                            );
                            print('로그아웃 실패: $e');
                          }
                        },
                        child: Text('profile.logout'.tr(),
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
