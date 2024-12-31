import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.assetPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 1,
        padding: EdgeInsets.zero,
        shape: CircleBorder(
          side: BorderSide(color: Colors.blue[50]!),
        ),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 0.w, right: 0.w),
          child: Image.asset(
            assetPath,
            height: 45,
            width: 45,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
