import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';

class DialogHelper {

  // 이메일 인증 확인 다이얼로그를 보여주는 메소드
  static void showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('이메일 인증 필요'),
          content: Text('이메일로 전송된 링크로 인증 하십시오.'),
          actions: [
            TextButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.checkEmailVerified();

                if (authProvider.isEmailVerified) {
                  Navigator.of(context).pop();
                  context.go('/login');
                } else {
                  _showNotVerifiedDialog(context);
                }
              },
              child: Text('인증 완료'),
            ),
          ],
        );
      },
    );
  }

  // showEmailVerificationDialog 메서드에서 인증 실패할 경우 나오는 다이얼로그를 보여주는 메서드
  static void _showNotVerifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('인증 미완료'),
          content: Text('이메일 인증이 완료되지 않았습니다. 다시 확인해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
