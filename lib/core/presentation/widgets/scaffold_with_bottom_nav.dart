import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/navigation_provider.dart';
import 'package:travel_on_final/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:travel_on_final/features/home/presentation/screens/home_screen.dart';
import 'package:travel_on_final/features/home/presentation/widgets/bottom_navigation_bar.dart';
import 'package:travel_on_final/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:travel_on_final/features/search/presentation/screens/detail_screens.dart';

class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: context.watch<NavigationProvider>().currentIndex,
        children: const [
          HomeScreen(),
          DetailScreen(),
          ChatListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, _) {
          return CustomBottomNavigationBar(
            selectedIndex: navigationProvider.currentIndex,
            onItemTapped: (index) => navigationProvider.setIndex(index),
          );
        },
      ),
    );
  }
}
