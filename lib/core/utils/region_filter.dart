import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';

class RegionFilter extends StatelessWidget {
  final Function(String) onRegionChanged;

  const RegionFilter({
    super.key,
    required this.onRegionChanged,
  });

  String _getRegionText(String region) {
    switch (region) {
      case 'seoul':
        return '서울';
      case 'incheon_gyeonggi':
        return '인천/경기';
      case 'gangwon':
        return '강원';
      case 'daejeon_chungnam':
        return '대전/충남';
      case 'chungbuk':
        return '충북';
      case 'gwangju_jeonnam':
        return '광주/전남';
      case 'jeonbuk':
        return '전북';
      case 'busan_gyeongnam':
        return '부산/경남';
      case 'daegu_gyeongbuk':
        return '대구/경북';
      case 'jeju':
        return '제주도';
      default:
        return '전체';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TravelProvider>(
      builder: (context, provider, child) => PopupMenuButton<String>(
        offset: const Offset(0, 40),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'all',
            child: Text('전체'),
          ),
          const PopupMenuItem(
            value: 'seoul',
            child: Text('서울'),
          ),
          const PopupMenuItem(
            value: 'incheon_gyeonggi',
            child: Text('인천/경기'),
          ),
          const PopupMenuItem(
            value: 'gangwon',
            child: Text('강원'),
          ),
          const PopupMenuItem(
            value: 'daejeon_chungnam',
            child: Text('대전/충남'),
          ),
          const PopupMenuItem(
            value: 'chungbuk',
            child: Text('충북'),
          ),
          const PopupMenuItem(
            value: 'gwangju_jeonnam',
            child: Text('광주/전남'),
          ),
          const PopupMenuItem(
            value: 'jeonbuk',
            child: Text('전북'),
          ),
          const PopupMenuItem(
            value: 'busan_gyeongnam',
            child: Text('부산/경남'),
          ),
          const PopupMenuItem(
            value: 'daegu_gyeongbuk',
            child: Text('대구/경북'),
          ),
          const PopupMenuItem(
            value: 'jeju',
            child: Text('제주도'),
          ),
        ],
        onSelected: onRegionChanged,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.travelonLightBlueColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getRegionText(provider.selectedRegion),
            style: const TextStyle(
              color: AppColors.travelonDarkBlueColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
