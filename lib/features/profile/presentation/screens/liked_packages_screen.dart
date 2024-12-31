import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/search/presentation/widgets/package_list.dart';

class LikedPackagesScreen extends StatelessWidget {
  const LikedPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.user.liked_packages'.tr()),
      ),
      body: Consumer2<AuthProvider, TravelProvider>(
        builder: (context, authProvider, travelProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Text('auth.login_required'.tr()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await travelProvider.loadPackages();
            },
            child: Builder(
              builder: (context) {
                final likedPackages = travelProvider.getLikedPackages();

                if (likedPackages.isEmpty) {
                  return Center(
                    child: Text('profile.user.no_liked_packages'.tr()),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: likedPackages.length,
                  itemBuilder: (context, index) {
                    return LikeablePackageCard(package: likedPackages[index]);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}