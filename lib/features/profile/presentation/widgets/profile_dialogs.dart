import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';

void showPasswordDialog(BuildContext context) {
  final TextEditingController passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('비밀번호 확인'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '비밀번호를 입력하세요',
            hintText: '비밀번호',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final isAuthenticated = await authProvider.checkPassword(passwordController.text);
              
              if (isAuthenticated) {
                Navigator.pop(context);
                context.push('/profile/edit');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('비밀번호가 올바르지 않습니다')),
                );
              }
            },
            child: Text('확인'),
          ),
        ],
      );
    },
  );
}
