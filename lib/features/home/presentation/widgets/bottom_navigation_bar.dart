import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:travel_on_final/core/providers/navigation_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.travelonBlueColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.house_alt_fill),
          label: 'navigation.home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.compass_fill),
          label: 'navigation.packages'.tr(),
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(CupertinoIcons.chat_bubble_2_fill),
              if (navigationProvider.totalUnreadCount > 0)
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      navigationProvider.totalUnreadDisplay,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          label: 'navigation.chat'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(CupertinoIcons.person_crop_circle_fill),
          label: 'navigation.mypage'.tr(),
        ),
      ],
      currentIndex: selectedIndex,
      onTap: onItemTapped,
    );
  }
}
