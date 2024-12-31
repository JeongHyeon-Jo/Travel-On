import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/regional_provider.dart';
import '../widgets/regional_spot_card.dart';
import '../widgets/region_selector.dart';
import '../widgets/category_filter.dart';

class RegionalExplorationScreen extends StatelessWidget {
  const RegionalExplorationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegionalProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('menu.local_tour'.tr()),
          ),
          body: Column(
            children: [
              const RegionSelector(),
              const CategoryFilter(),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? Center(child: Text(provider.error!))
                        : provider.spots.isEmpty
                            ? Center(
                                child: Text(
                                  provider.selectedCity == null
                                      ? 'regional.select_region'.tr()
                                      : 'regional.no_spots'.tr(),
                                ),
                              )
                            : ListView.builder(
                                itemCount: provider.spots.length,
                                itemBuilder: (context, index) {
                                  return RegionalSpotCard(
                                    spot: provider.spots[index],
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
