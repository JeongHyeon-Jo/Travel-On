import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/recommendation_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/recommendation_card.dart';
import 'package:easy_localization/easy_localization.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context
          .read<RecommendationProvider>()
          .generateRecommendations(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'recommendation.title'.tr(),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.recommendedPackages.isEmpty) {
            return Center(
              child: Text('recommendation.empty'.tr()),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: provider.recommendedPackages.length,
            itemBuilder: (context, index) {
              final package = provider.recommendedPackages[index];
              return RecommendationCard(
                package: package,
                rank: index + 1,
              );
            },
          );
        },
      ),
    );
  }
}
