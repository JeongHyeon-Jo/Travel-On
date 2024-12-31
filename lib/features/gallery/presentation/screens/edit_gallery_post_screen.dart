import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/gallery_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import '../../../reservation/presentation/providers/reservation_provider.dart';
import '../../../reservation/domain/entities/reservation_entity.dart';

class EditGalleryPostScreen extends StatefulWidget {
  final String postId;
  final String location;
  final String description;
  final String imageUrl;
  final String? packageId;
  final String? packageTitle;

  const EditGalleryPostScreen({
    super.key,
    required this.postId,
    required this.location,
    required this.description,
    required this.imageUrl,
    this.packageId,
    this.packageTitle,
  });

  @override
  State<EditGalleryPostScreen> createState() => _EditGalleryPostScreenState();
}

class _EditGalleryPostScreenState extends State<EditGalleryPostScreen> {
  File? _image;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedPackageId;
  List<ReservationEntity> _confirmedReservations = [];

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.location;
    _descriptionController.text = widget.description;
    _selectedPackageId = widget.packageId;
    _loadConfirmedReservations();
  }

  Future<void> _loadConfirmedReservations() async {
    final userId = context.read<AuthProvider>().currentUser!.id;
    await context.read<ReservationProvider>().loadReservations(userId);
    setState(() {
      _confirmedReservations = context
          .read<ReservationProvider>()
          .reservations
          .where((r) => r.status == 'approved')
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? selectedPackageTitle;
      if (_selectedPackageId != null) {
        final selectedReservation = _confirmedReservations.firstWhere(
          (r) => r.packageId == _selectedPackageId,
          orElse: () => throw Exception('선택한 패키지를 찾을 수 없습니다'),
        );
        selectedPackageTitle = selectedReservation.packageTitle;
      }

      await context.read<GalleryProvider>().updatePost(
            postId: widget.postId,
            location: _locationController.text,
            description: _descriptionController.text,
            newImage: _image,
            packageId: _selectedPackageId,
            packageTitle: selectedPackageTitle,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updatePost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('완료'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0XFF2196F3)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: '위치',
                    hintText: '예: 서울 남산타워',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Color(0XFF2196F3)),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '위치를 입력해주세요' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: '설명',
                    hintText: '여행 경험을 공유해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Color(0XFF2196F3)),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? '설명을 입력해주세요' : null,
                ),
                if (_confirmedReservations.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  DropdownButtonFormField<String>(
                    value: _selectedPackageId,
                    decoration: InputDecoration(
                      labelText: '여행 패키지 태그',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Color(0XFF2196F3)),
                      ),
                      prefixIcon: const Icon(Icons.local_offer),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    hint: const Text('관련 패키지 선택 (선택사항)'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('선택 안함'),
                      ),
                      ..._confirmedReservations.map((reservation) {
                        return DropdownMenuItem(
                          value: reservation.packageId,
                          child: Text(
                            reservation.packageTitle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPackageId = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
