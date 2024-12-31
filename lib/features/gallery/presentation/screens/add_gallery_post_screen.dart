import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/gallery_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import '../../../reservation/presentation/providers/reservation_provider.dart';
import '../../../reservation/domain/entities/reservation_entity.dart';

class AddGalleryPostScreen extends StatefulWidget {
  const AddGalleryPostScreen({super.key});

  @override
  State<AddGalleryPostScreen> createState() => _AddGalleryPostScreenState();
}

class _AddGalleryPostScreenState extends State<AddGalleryPostScreen> {
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

  Future<void> _uploadPost() async {
    if (!_formKey.currentState!.validate() || _image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().currentUser!;

      // 선택된 패키지의 정보 가져오기
      String? selectedPackageTitle;
      if (_selectedPackageId != null) {
        final selectedReservation = _confirmedReservations.firstWhere(
          (r) => r.packageId == _selectedPackageId,
          orElse: () => throw Exception(
              'gallery.post.add_post.upload.package_not_found'.tr()),
        );
        selectedPackageTitle = selectedReservation.packageTitle;
      }

      await context.read<GalleryProvider>().uploadPost(
            userId: user.id,
            username: user.name,
            userProfileUrl: user.profileImageUrl,
            imageFile: _image!,
            location: _locationController.text,
            description: _descriptionController.text,
            packageId: _selectedPackageId,
            packageTitle: selectedPackageTitle,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('gallery.post.add_post.upload.success'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery.post.add_post.upload.error'
                .tr(namedArgs: {'error': e.toString()})),
          ),
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
        title: Text('gallery.post.add_post.title'.tr()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadPost,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'gallery.post.add_post.share'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.r,
              right: 16.r,
              top: 16.r,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.r,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
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
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50.r,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text('gallery.post.add_post.add_image'.tr()),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'gallery.post.add_post.location.label'.tr(),
                      hintText: 'gallery.post.add_post.location.hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: Color(0XFF2196F3),
                        ),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'gallery.post.add_post.location.error'.tr()
                        : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'gallery.post.add_post.description.label'.tr(),
                      hintText: 'gallery.post.add_post.description.hint'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: Color(0XFF2196F3),
                        ),
                      ),
                      prefixIcon: const Icon(Icons.description),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'gallery.post.add_post.description.error'.tr()
                        : null,
                  ),
                  if (_confirmedReservations.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    DropdownButtonFormField<String>(
                      value: _selectedPackageId,
                      decoration: InputDecoration(
                        labelText:
                            'gallery.post.add_post.package_tag.label'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                            color: Color(0XFF2196F3),
                          ),
                        ),
                        prefixIcon: const Icon(Icons.local_offer),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      hint: Text('gallery.post.add_post.package_tag.hint'.tr()),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                              'gallery.post.add_post.package_tag.none'.tr()),
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
                  SizedBox(height: 16.h),
                ],
              ),
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
