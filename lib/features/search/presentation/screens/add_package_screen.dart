import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/map/domain/entities/travel_point.dart';
import 'package:travel_on_final/features/map/presentation/widgets/route_editor.dart';
import 'dart:io';
import '../providers/travel_provider.dart';
import '../../domain/entities/travel_package.dart';

class AddPackageScreen extends StatefulWidget {
  const AddPackageScreen({super.key});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedRegion = 'seoul';
  File? _mainImage;
  final List<File> _descriptionImages = [];
  final _picker = ImagePicker();
  final _maxParticipantsController = TextEditingController();
  int _nights = 1; // 기본값 1박
  final Set<int> _selectedDepartureDays = {}; // 선택된 출발 요일들
  final _minParticipantsController = TextEditingController();
  List<TravelPoint> _routePoints = [];

  final List<Map<String, dynamic>> _weekDays = [
    {'value': 1, 'label': '월'},
    {'value': 2, 'label': '화'},
    {'value': 3, 'label': '수'},
    {'value': 4, 'label': '목'},
    {'value': 5, 'label': '금'},
    {'value': 6, 'label': '토'},
    {'value': 7, 'label': '일'},
  ];

  final Map<String, bool> _selectedLanguages = {
    'ko': true,
    'en': false,
    'ja': false,
    'zh': false,
  };

  final Map<String, TextEditingController> _titleControllers = {
    'ko': TextEditingController(),
    'en': TextEditingController(),
    'ja': TextEditingController(),
    'zh': TextEditingController(),
  };

  final Map<String, TextEditingController> _descriptionControllers = {
    'ko': TextEditingController(),
    'en': TextEditingController(),
    'ja': TextEditingController(),
    'zh': TextEditingController(),
  };

  Widget _buildLanguageSection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0XFF2196F3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지원 언어', style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8,
            children: [
              _buildLanguageChip('ko', '한국어'),
              _buildLanguageChip('en', 'English'),
              _buildLanguageChip('ja', '日本語'),
              _buildLanguageChip('zh', '中文'),
            ],
          ),
          SizedBox(height: 16.h),
          ..._selectedLanguages.entries
              .where((e) => e.value)
              .map((e) => _buildLanguageFields(e.key)),
        ],
      ),
    );
  }

  Widget _buildLanguageFields(String langCode) {
    final labels = {
      'ko': '한국어',
      'en': 'English',
      'ja': '日本語',
      'zh': '中文',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${labels[langCode]} 입력',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _titleControllers[langCode],
          decoration: InputDecoration(
            labelText: '패키지 제목 (${labels[langCode]})',
            hintText: '예: 서울 시티 투어',
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          validator: langCode == 'ko'
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '한국어 제목은 필수입니다';
                  }
                  return null;
                }
              : null,
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _descriptionControllers[langCode],
          maxLines: 5,
          decoration: InputDecoration(
            labelText: '패키지 설명 (${labels[langCode]})',
            hintText: '패키지에 대한 상세 설명을 입력해주세요',
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          validator: langCode == 'ko'
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '한국어 설명은 필수입니다';
                  }
                  return null;
                }
              : null,
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  void dispose() {
    // 기존 dispose 코드 제거하고 새로운 컨트롤러들 dispose
    for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _minParticipantsController.dispose();
    super.dispose();
  }

  Widget _buildNightsSelection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0XFF2196F3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('기간:', style: TextStyle(fontSize: 16.sp)),
          DropdownButton<int>(
            value: _nights,
            isDense: true,
            underline: Container(), // 드롭다운 버튼의 기본 밑줄 제거
            items: List.generate(7, (index) => index + 1).map((nights) {
              return DropdownMenuItem(
                value: nights,
                child: Text('$nights박${nights + 1}일'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _nights = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepartureDaysSelection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0XFF2196F3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('출발 요일', style: TextStyle(fontSize: 16.sp)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _weekDays.map((day) {
              final isSelected = _selectedDepartureDays.contains(day['value']);
              return ChoiceChip(
                label: Text(
                  day['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                showCheckmark: false, // 체크마크 비활성화
                selectedColor: Colors.blue,
                backgroundColor: Colors.white,
                side: BorderSide(color: isSelected ? Colors.blue : Colors.grey),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDepartureDays.add(day['value']);
                    } else {
                      _selectedDepartureDays.remove(day['value']);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  final List<String> _regions = [
    'seoul',
    'incheon_gyeonggi',
    'gangwon',
    'daejeon_chungnam',
    'chungbuk',
    'gwangju_jeonnam',
    'jeonbuk',
    'busan_gyeongnam',
    'daegu_gyeongbuk',
    'jeju',
  ];

  Future<void> _pickMainImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mainImage = File(image.path);
      });
    }
  }

  Future<void> _pickDescriptionImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _descriptionImages.add(File(image.path));
      });
    }
  }

  void _removeDescriptionImage(int index) {
    setState(() {
      _descriptionImages.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartureDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출발 요일을 선택해주세요')),
        );
        return;
      }

      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser!;

      final newPackage = TravelPackage(
        id: DateTime.now().toString(),
        title: _titleControllers['ko']!.text,
        titleEn: _titleControllers['en']!.text,
        titleJa: _titleControllers['ja']!.text,
        titleZh: _titleControllers['zh']!.text,
        description: _descriptionControllers['ko']!.text,
        descriptionEn: _descriptionControllers['en']!.text,
        descriptionJa: _descriptionControllers['ja']!.text,
        descriptionZh: _descriptionControllers['zh']!.text,
        price: double.parse(_priceController.text),
        region: _selectedRegion,
        mainImage: _mainImage?.path,
        descriptionImages: _descriptionImages.map((file) => file.path).toList(),
        guideName: user.name,
        guideId: user.id,
        minParticipants: int.parse(_minParticipantsController.text),
        maxParticipants: int.parse(_maxParticipantsController.text),
        nights: _nights,
        departureDays: _selectedDepartureDays.toList()..sort(),
        routePoints: _routePoints,
        totalDays: _nights + 1,
      );

      context.read<TravelProvider>().addPackage(newPackage);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 패키지 등록'),
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMainImageSection(),
                SizedBox(height: 16.h),
                _buildLanguageSection(), // 언어 선택 섹션 추가
                SizedBox(height: 16.h),
                _buildBasicInfoSection(),
                SizedBox(height: 16.h),
                _buildNightsSelection(),
                SizedBox(height: 16.h),
                _buildDepartureDaysSelection(),
                SizedBox(height: 16.h),
                _buildRouteSelection(),
                SizedBox(height: 16.h),
                _buildParticipantsSection(),
                SizedBox(height: 16.h),
                _buildDescriptionImagesSection(),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                  child: const Text('패키지 등록', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSelection() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0XFF2196F3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('여행 코스', style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 8.h),
          SizedBox(
            height: 400,
            child: RouteEditor(
              points: _routePoints,
              totalDays: _nights + 1, // ex) 2박3일이면 3
              onPointsChanged: (updatedPoints) {
                setState(() {
                  _routePoints = updatedPoints;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainImageSection() {
    return GestureDetector(
      onTap: _pickMainImage,
      child: Container(
        height: 200.h,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0XFF2196F3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _mainImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_mainImage!,
                    fit: BoxFit.cover, width: double.infinity),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 50),
                  Text('메인 이미지 추가'),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: const InputDecoration(
            labelText: '지역',
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          items: _regions.map((region) {
            return DropdownMenuItem(
              value: region,
              child: Text(_getRegionLabel(region)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedRegion = value!),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '가격',
            hintText: '예: 50000',
            prefixText: '₩ ',
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          validator: _validatePrice,
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      children: [
        TextFormField(
          controller: _minParticipantsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '최소 인원',
            hintText: '예: 2',
            suffixText: '명',
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          validator: _validateMinParticipants,
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _maxParticipantsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '최대 인원',
            hintText: '예: 10',
            suffixText: '명',
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFF2196F3)),
            ),
          ),
          validator: _validateMaxParticipants,
        ),
      ],
    );
  }

  Widget _buildDescriptionImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('설명 이미지',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._descriptionImages
                .asMap()
                .entries
                .map(_buildDescriptionImageItem),
            _buildAddImageButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickDescriptionImage,
      child: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate),
            Text('추가'),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionImageItem(MapEntry<int, File> entry) {
    return Stack(
      children: [
        Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(entry.value, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            icon: const Icon(Icons.remove_circle),
            color: Colors.red,
            onPressed: () => _removeDescriptionImage(entry.key),
          ),
        ),
      ],
    );
  }

  String? _validateMaxParticipants(String? value) {
    if (value == null || value.isEmpty) {
      return '최대 인원을 입력해주세요';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return '유효한 인원 수를 입력해주세요';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return '가격을 입력해주세요';
    }
    if (double.tryParse(value) == null) {
      return '유효한 숫자를 입력해주세요';
    }
    return null;
  }

  String _getRegionLabel(String region) {
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

  Widget _buildLanguageChip(String code, String label) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isDarkMode
              ? Colors.white
              : _selectedLanguages[code]!
                  ? Colors.white
                  : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: _selectedLanguages[code]!,
      selectedColor: AppColors.travelonBlueColor,
      backgroundColor: Colors.transparent,
      checkmarkColor: Colors.white,
      onSelected: (bool selected) {
        setState(() {
          if (code == 'ko' && !selected) {
            return; // 한국어는 필수
          }
          _selectedLanguages[code] = selected;
        });
      },
    );
  }

  String? _validateMinParticipants(String? value) {
    if (value == null || value.isEmpty) {
      return '최소 인원을 입력해주세요';
    }
    final minNumber = int.tryParse(value);
    if (minNumber == null || minNumber <= 0) {
      return '유효한 인원 수를 입력해주세요';
    }
    final maxNumber = int.tryParse(_maxParticipantsController.text) ?? 0;
    if (minNumber > maxNumber) {
      return '최소 인원이 최대 인원보다 클 수 없습니다';
    }
    return null;
  }
}
