import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:travel_on_final/core/providers/theme_provider.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/features/auth/presentation/widgets/text_field_widget.dart';
import 'package:travel_on_final/features/auth/presentation/widgets/password_field_widget.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _saveCredentials = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = _prefs?.getString('savedEmail') ?? '';
      _passwordController.text = _prefs?.getString('savedPassword') ?? '';
      _saveCredentials = _prefs?.getBool('saveCredentials') ?? false;
    });
  }

  Widget _buildLanguageSelector() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Row(
      children: [
        Text(
          _getLanguageLabel(context.locale),
          style: TextStyle(fontSize: 14.sp),
        ),
        PopupMenuButton<Locale>(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          icon: const Icon(Icons.language),
          onSelected: (Locale locale) {
            context.setLocale(locale);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: const Locale('ko', 'KR'),
              child: Row(
                children: [
                  Text('🇰🇷', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  const Text('한국어'),
                ],
              ),
            ),
            PopupMenuItem(
              value: const Locale('en', 'US'),
              child: Row(
                children: [
                  Text('🇺🇸', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  const Text('English'),
                ],
              ),
            ),
            PopupMenuItem(
              value: const Locale('ja', 'JP'),
              child: Row(
                children: [
                  Text('🇯🇵', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  const Text('日本語'),
                ],
              ),
            ),
            PopupMenuItem(
              value: const Locale('zh', 'CN'),
              child: Row(
                children: [
                  Text('🇨🇳', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 8.w),
                  const Text('中文'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getLanguageLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '🇰🇷한국어';
      case 'en':
        return '🇺🇸English';
      case 'ja':
        return '🇯🇵日本語';
      case 'zh':
        return '🇨🇳中文';
      default:
        return 'Language';
    }
  }

  Future<void> _saveCredentialsToPrefs() async {
    if (_saveCredentials) {
      await _prefs?.setString('savedEmail', _emailController.text);
      await _prefs?.setString('savedPassword', _passwordController.text);
      await _prefs?.setBool('saveCredentials', _saveCredentials);
    } else {
      await _prefs?.remove('savedEmail');
      await _prefs?.remove('savedPassword');
      await _prefs?.remove('saveCredentials');
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(_emailController.text, _passwordController.text);

      if (mounted) {
        if (authProvider.isAuthenticated) {
          await _saveCredentialsToPrefs();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('login.welcome'
                  .tr(namedArgs: {'name': authProvider.currentUser!.name})),
            ),
          );
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('login.login_failed'.tr())),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetPassword() => context.push('/reset_password');
  void _navigateToSignup() => context.push('/signup');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [_buildLanguageSelector()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/travelon_small.png',
              height: 200.h,
              width: 200.w,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return Icon(Icons.error, size: 100.sp, color: Colors.grey);
              },
            ),
            TextFieldWidget(
              controller: _emailController,
              labelText: 'login.email'.tr(),
            ),
            SizedBox(height: 20.h),
            PasswordFieldWidget(
              controller: _passwordController,
              labelText: 'login.password'.tr(),
            ),
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8.0.w),
                  child: Row(
                    children: [
                      Text('login.save_info'.tr(),
                          style: TextStyle(fontSize: 14.sp)),
                      Checkbox(
                        value: _saveCredentials,
                        onChanged: (value) {
                          setState(() => _saveCredentials = value ?? false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _navigateToSignup,
                  child: Text(
                    'login.signup'.tr(),
                    style: TextStyle(
                        color: AppColors.travelonBlueColor, fontSize: 14.sp),
                  ),
                ),
                Text('·',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    'login.reset_password'.tr(),
                    style: TextStyle(
                        color: AppColors.travelonBlueColor, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.travelonBlueColor,
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child:
                          const CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      'login.login_button'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
            ),
            SizedBox(height: 10.h),
            _buildDivider(),
            SizedBox(height: 10.h),
            Text(
              'login.sns_login'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20.h),
            _buildSocialButtons(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'login.or'.tr(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          iconWidget: _buildSocialIcon('google_light.png', 58),
          color: Colors.white,
          onPressed: _handleGoogleSignIn,
        ),
        SizedBox(width: 20.w),
        _buildSocialButton(
          iconWidget: _buildSocialIcon('github_light.png', 34),
          color: Colors.white,
          onPressed: _handleGithubSignIn,
        ),
        // SizedBox(width: 20.w),
        // _buildSocialButton(
        //   iconWidget: _buildSocialIcon('naver_light.png', 40),
        //   color: const Color(0xFF03C75A),
        //   onPressed: () {}, // Naver login implementation
        // ),
        SizedBox(width: 20.w),
        _buildSocialButton(
          iconWidget: _buildSocialIcon('kakao_light.png', 100),
          color: const Color(0xFFFEE500),
          onPressed: _handleKakaoSignIn,
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String assetName, double size) {
    return ClipOval(
      child: Image.asset(
        'assets/images/$assetName',
        width: size.sp,
        height: size.sp,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget iconWidget,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 45.w,
        height: 45.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: iconWidget),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithGoogle();

      if (authProvider.isAuthenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login.welcome'
                .tr(namedArgs: {'name': authProvider.currentUser!.name})),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login.google_failed'.tr())),
        );
      }
    }
  }

  Future<void> _handleGithubSignIn() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithGithub(context);

      if (authProvider.isAuthenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login.welcome'
                .tr(namedArgs: {'name': authProvider.currentUser!.name})),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login.github_failed'.tr())),
        );
      }
    }
  }

  Future<void> _handleKakaoSignIn() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithKakao(context);

      if (authProvider.isAuthenticated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login.welcome'
                .tr(namedArgs: {'name': authProvider.currentUser!.name})),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login.kakao_failed'.tr())),
        );
      }
    }
  }
}
