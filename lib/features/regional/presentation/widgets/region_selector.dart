import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/regional_provider.dart';
import '../../../../core/constants/region_codes.dart';

class RegionSelector extends StatelessWidget {
  const RegionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegionalProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'region_selector.city'.tr(),
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: provider.selectedCity,
                items: RegionCodes.cityCodes.keys.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: provider.setCity,
              ),
              const SizedBox(height: 16),
              if (provider.selectedCity != null &&
                  provider.selectedCity != '전체')
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'region_selector.district'.tr(),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: provider.selectedDistrict,
                  items: RegionCodes
                      .districtCodes[
                          RegionCodes.getCityCode(provider.selectedCity!)]
                      ?.keys
                      .map((String district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: provider.setDistrict,
                ),
            ],
          ),
        );
      },
    );
  }
}
