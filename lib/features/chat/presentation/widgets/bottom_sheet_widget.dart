import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';

class BottomSheetWidget {
  final ImagePicker _picker = ImagePicker();

  void showBottomSheetMenu({
    required BuildContext parentContext,
    required String chatId,
    required String userId,
    required String otherUserId,
    required String currentUserProfileImage,
    required String username,
    double initialHeightFactor = 0.15,
  }) {
    final isDarkMode =
        Provider.of<ThemeProvider>(parentContext, listen: false).isDarkMode;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: initialHeightFactor,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 13.w),
                // 갤러리 버튼
                buildIconButton(
                  context,
                  icon: Icons.image,
                  label: 'gallery', // 'chat.add_content.gallery' 키와 매칭
                  backgroundColor: Colors.lightBlue,
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      _showConfirmationDialog(
                          parentContext,
                          image,
                          chatId,
                          userId,
                          otherUserId,
                          currentUserProfileImage,
                          username);
                    }
                  },
                ),
                SizedBox(width: 15.w),
                // 카메라 버튼
                buildIconButton(
                  context,
                  icon: Icons.camera_alt,
                  label: 'camera', // 'chat.add_content.camera' 키와 매칭
                  backgroundColor: Colors.blueAccent,
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (image != null) {
                      _showConfirmationDialog(
                          parentContext,
                          image,
                          chatId,
                          userId,
                          otherUserId,
                          currentUserProfileImage,
                          username);
                    }
                  },
                ),
                SizedBox(width: 15.w),
                // 사용자 버튼
                buildIconButton(
                  context,
                  icon: Icons.person,
                  label: 'user', // 'chat.add_content.user' 키와 매칭
                  backgroundColor: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/user-search',
                      extra: {'chatId': chatId, 'otherUserId': otherUserId},
                    );
                  },
                ),
                SizedBox(width: 15.w),
                // 패키지 버튼
                buildIconButton(
                  context,
                  icon: Icons.card_travel,
                  label: 'package', // 'chat.add_content.package' 키와 매칭
                  backgroundColor: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/package-search',
                      extra: {'chatId': chatId, 'otherUserId': otherUserId},
                    );
                  },
                ),
                SizedBox(width: 15.w),
                // 지도 버튼
                buildIconButton(
                  context,
                  icon: Icons.map,
                  label: 'map', // 'chat.add_content.map' 키와 매칭
                  backgroundColor: const Color(0xFF03C75A),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/map-search',
                      extra: {'chatId': chatId, 'otherUserId': otherUserId},
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: CircleAvatar(
            backgroundColor: backgroundColor,
            radius: 27.w,
            child: Icon(icon, size: 28.w, color: Colors.white),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'chat.add_content.$label'.tr(),
          style: TextStyle(
            fontSize: 12.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    XFile image,
    String chatId,
    String userId,
    String otherUserId,
    String currentUserProfileImage,
    String username,
  ) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'chat.add_content.image.send'.tr(),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Image.file(File(image.path)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'chat.add_content.image.no'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final chatProvider =
                    Provider.of<ChatProvider>(context, listen: false);
                chatProvider.sendMessageToChat(
                  chatId: chatId,
                  text: '[Image]',
                  otherUserId: otherUserId,
                  imageFile: image,
                  context: context,
                );
              },
              child: Text(
                'chat.add_content.image.yes'.tr(),
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
