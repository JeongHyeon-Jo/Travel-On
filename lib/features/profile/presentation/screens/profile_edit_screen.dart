import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  String? _gender;
  DateTime? _birthDate;
  String? _profileImageUrl;
  File? _selectedImageFile;
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        setState(() {
          _nameController.text = user.name;
          _gender = user.gender;
          _birthDate = user.birthDate;
          _profileImageUrl = user.profileImageUrl;
          _introductionController.text = user.introduction ?? '';
        });
      }
    });
  }

  Future<void> _selectBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _birthDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _profileImageUrl = null;
      });
    }
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.length >= 2 && _nameController.text.length <= 8;
    });
  }

  void _saveProfile() async {
    _validateName();

    if (!_isNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이름은 2글자 이상 8글자 이하로 설정해야 합니다.')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이름은 비어 있을 수 없습니다.')),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().updateUserProfile(
        name: _nameController.text,
        gender: _gender,
        birthDate: _birthDate,
        profileImageUrl: _selectedImageFile != null ? _selectedImageFile!.path : _profileImageUrl,
        introduction: _introductionController.text,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 업데이트에 실패했습니다.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final authProvider = context.read<AuthProvider>();
    final TextEditingController passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("회원 탈퇴"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("회원 탈퇴를 진행하시겠습니까?"),
              SizedBox(height: 8.0),
              Text("탈퇴 후 복구는 불가능합니다.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호를 입력해주세요...',
                    border: InputBorder.none,
                  ),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("탈퇴", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final password = passwordController.text.trim();
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호를 입력해주세요.')),
        );
        return;
      }

      try {
        await authProvider.deleteAccount(context, password);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
        );
        context.go('/login');
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('권한 부족: 관리자에게 문의하세요.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원 탈퇴 실패: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('회원 정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InkWell(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _selectedImageFile != null
                    ? FileImage(_selectedImageFile!)
                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        ? NetworkImage(_profileImageUrl!)
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _nameController,
                onChanged: (_) => _validateName(),
                decoration: InputDecoration(
                  labelText: '이름',
                  labelStyle: TextStyle(color: Colors.blue),
                  border: InputBorder.none,
                  errorText: !_isNameValid ? '이름은 2글자 이상 8글자 이하여야 합니다.' : null,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: '이메일',
                  labelStyle: TextStyle(color: Colors.blue),
                  border: InputBorder.none,
                ),
                controller: TextEditingController(text: user?.email ?? ''),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _introductionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '내 소개',
                  labelStyle: TextStyle(color: Colors.blue),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '성별',
                    style: TextStyle(color: Colors.blue),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _gender = '남성';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _gender == '남성' ? Colors.blue.shade100 : null,
                          side: BorderSide(color: Colors.blue),
                        ),
                        child: Text('남성'),
                      ),
                      SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _gender = '여성';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _gender == '여성' ? Colors.blue.shade100 : null,
                          side: BorderSide(color: Colors.blue),
                        ),
                        child: Text('여성'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '생일',
                    style: TextStyle(color: Colors.blue,),
                  ),
                  Text(
                    _birthDate != null
                        ? "${_birthDate!.year}-${_birthDate!.month}-${_birthDate!.day}"
                        : '생일을 선택하세요 →',
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.blue),
                    onPressed: _selectBirthDate,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isNameValid ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                side: BorderSide(color: Colors.lightBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                '저장',
                style: TextStyle(
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: _deleteAccount,
              child: Text(
                '회원 탈퇴',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
