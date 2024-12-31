import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';

class RegionFilter extends StatelessWidget {
  final Function(String) onRegionChanged;

  const RegionFilter({
    super.key,
    required this.onRegionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return PopupMenuButton<String>(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      icon: const Icon(Icons.filter_list),
      onSelected: onRegionChanged,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'all',
          child: Text('regions.all'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'seoul',
          child: Text('regions.seoul'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'incheon_gyeonggi',
          child: Text('regions.incheon_gyeonggi'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'gangwon',
          child: Text('regions.gangwon'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'daejeon_chungnam',
          child: Text('regions.daejeon_chungnam'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'chungbuk',
          child: Text('regions.chungbuk'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'gwangju_jeonnam',
          child: Text('regions.gwangju_jeonnam'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'jeonbuk',
          child: Text('regions.jeonbuk'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'busan_gyeongnam',
          child: Text('regions.busan_gyeongnam'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'daegu_gyeongbuk',
          child: Text('regions.daegu_gyeongbuk'.tr()),
        ),
        PopupMenuItem<String>(
          value: 'jeju',
          child: Text('regions.jeju'.tr()),
        ),
      ],
    );
  }
}
