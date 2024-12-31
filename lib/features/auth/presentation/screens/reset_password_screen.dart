import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/auth/domain/usecases/reset_password_usecase.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetPasswordEmail() async {
    setState(() => _isLoading = true);
    final resetPasswordUseCase =
        Provider.of<ResetPasswordUseCase>(context, listen: false);
    try {
      await resetPasswordUseCase.call(_emailController.text);
      _showConfirmationDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('메일 전송 완료'),
        content: const Text('비밀번호 재설정 메일을 보냈습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('비밀번호 재설정', style: TextStyle(fontSize: 20.sp))),
      body: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.travelonBlueColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  labelStyle: TextStyle(
                      color: AppColors.travelonBlueColor, fontSize: 14.sp),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResetPasswordEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.travelonBlueColor,
                padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 16.h),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      '비밀번호 재설정',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
