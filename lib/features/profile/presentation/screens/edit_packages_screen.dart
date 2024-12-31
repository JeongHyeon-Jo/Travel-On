import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';

class EditPackageScreen extends StatefulWidget {
  final TravelPackage package;

  const EditPackageScreen({
    super.key,
    required this.package,
  });

  @override
  State<EditPackageScreen> createState() => _EditPackageScreenState();
}

class _EditPackageScreenState extends State<EditPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _minParticipantsController;
  late String _selectedRegion;
  File? _mainImage;
  final List<File> _newDescriptionImages = [];
  final List<String> _existingDescriptionImages = [];
  final _picker = ImagePicker();
  late int _nights;
  final Set<int> _selectedDepartureDays = {};

  final List<Map<String, dynamic>> _weekDays = [
    {'value': 1, 'label': '월'},
    {'value': 2, 'label': '화'},
    {'value': 3, 'label': '수'},
    {'value': 4, 'label': '목'},
    {'value': 5, 'label': '금'},
    {'value': 6, 'label': '토'},
    {'value': 7, 'label': '일'},
  ];

  @override
  void initState() {
    super.initState();
    // 기존 패키지 데이터로 초기화
    _titleController = TextEditingController(text: widget.package.title);
    _descriptionController =
        TextEditingController(text: widget.package.description);
    _priceController =
        TextEditingController(text: widget.package.price.toString());
    _selectedRegion = widget.package.region;
    _maxParticipantsController =
        TextEditingController(text: widget.package.maxParticipants.toString());
    _minParticipantsController =
        TextEditingController(text: widget.package.minParticipants.toString());
    _nights = widget.package.nights;
    _selectedDepartureDays.addAll(widget.package.departureDays);
    _existingDescriptionImages.addAll(widget.package.descriptionImages);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _minParticipantsController.dispose();
    super.dispose();
  }

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
        _newDescriptionImages.add(File(image.path));
      });
    }
  }

  void _removeNewDescriptionImage(int index) {
    setState(() {
      _newDescriptionImages.removeAt(index);
    });
  }

  void _removeExistingDescriptionImage(int index) {
    setState(() {
      _existingDescriptionImages.removeAt(index);
    });
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
          const Text('박 수:', style: TextStyle(fontSize: 16)),
          DropdownButton<int>(
            value: _nights,
            isDense: true,
            underline: Container(),
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
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
                showCheckmark: false,
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDepartureDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출발 요일을 선택해주세요')),
        );
        return;
      }

      try {
        final updatedPackage = TravelPackage(
          id: widget.package.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          region: _selectedRegion,
          mainImage: _mainImage?.path ?? widget.package.mainImage,
          descriptionImages: [
            ..._existingDescriptionImages,
            ..._newDescriptionImages.map((file) => file.path),
          ],
          guideName: widget.package.guideName,
          guideId: widget.package.guideId,
          minParticipants: int.parse(_minParticipantsController.text),
          maxParticipants: int.parse(_maxParticipantsController.text),
          nights: _nights,
          departureDays: _selectedDepartureDays.toList()..sort(),
          totalDays: _nights + 1,
          routePoints: widget.package.routePoints,
        );

        await context.read<TravelProvider>().updatePackage(updatedPackage);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('패키지가 수정되었습니다')),
          );
          context.pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('패키지 수정'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 메인 이미지
                GestureDetector(
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
                            child: Image.file(
                              _mainImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : widget.package.mainImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.package.mainImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 50),
                                  Text('메인 이미지 수정'),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),

                // 제목
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '패키지 제목',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 지역 선택
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: '지역',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'seoul', child: Text('서울')),
                    DropdownMenuItem(
                        value: 'incheon_gyeonggi', child: Text('인천/경기')),
                    DropdownMenuItem(value: 'gangwon', child: Text('강원')),
                    DropdownMenuItem(
                        value: 'daejeon_chungnam', child: Text('대전/충남')),
                    DropdownMenuItem(value: 'chungbuk', child: Text('충북')),
                    DropdownMenuItem(
                        value: 'gwangju_jeonnam', child: Text('광주/전남')),
                    DropdownMenuItem(value: 'jeonbuk', child: Text('전북')),
                    DropdownMenuItem(
                        value: 'busan_gyeongnam', child: Text('부산/경남')),
                    DropdownMenuItem(
                        value: 'daegu_gyeongbuk', child: Text('대구/경북')),
                    DropdownMenuItem(value: 'jeju', child: Text('제주도')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value!;
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // 가격
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '가격',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                    prefixText: '₩ ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '가격을 입력해주세요';
                    }
                    if (double.tryParse(value) == null) {
                      return '유효한 숫자를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 박 수 선택
                _buildNightsSelection(),
                SizedBox(height: 16.h),

                // 출발 요일 선택
                _buildDepartureDaysSelection(),
                SizedBox(height: 16.h),

                // 최소 인원
                TextFormField(
                  controller: _minParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '최소 인원',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                    suffixText: '명',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '최소 인원을 입력해주세요';
                    }
                    final minNumber = int.tryParse(value);
                    if (minNumber == null || minNumber <= 0) {
                      return '유효한 인원 수를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 최대 인원
                TextFormField(
                  controller: _maxParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '최대 인원',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                    suffixText: '명',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '최대 인원을 입력해주세요';
                    }
                    final maxNumber = int.tryParse(value);
                    if (maxNumber == null || maxNumber <= 0) {
                      return '유효한 인원 수를 입력해주세요';
                    }
                    final minNumber =
                        int.tryParse(_minParticipantsController.text) ?? 0;
                    if (maxNumber < minNumber) {
                      return '최대 인원은 최�� 인원보다 작을 수 없습니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 설명
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '패키지 설명',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0XFF2196F3)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '설명을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 설명 이미지 목록
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '설명 이미지',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 기존 이미지
                        ..._existingDescriptionImages
                            .asMap()
                            .entries
                            .map((entry) {
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
                                  child: Image.network(
                                    entry.value,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                  onPressed: () =>
                                      _removeExistingDescriptionImage(
                                          entry.key),
                                ),
                              ),
                            ],
                          );
                        }),
                        // 새로 추가된 이미지
                        ..._newDescriptionImages.asMap().entries.map((entry) {
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
                                  child: Image.file(
                                    entry.value,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                  onPressed: () =>
                                      _removeNewDescriptionImage(entry.key),
                                ),
                              ),
                            ],
                          );
                        }),
                        // 이미지 추가 버튼
                        GestureDetector(
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
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // 수정 버튼
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '패키지 수정',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
