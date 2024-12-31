import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:travel_on_final/core/theme/colors.dart';
import 'package:travel_on_final/firebase_options.dart';

// Providers
import 'package:provider/provider.dart';
import 'package:travel_on_final/core/providers/navigation_provider.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart'
    as app;
import 'package:travel_on_final/features/chat/presentation/providers/chat_provider.dart';
import 'package:travel_on_final/features/guide/presentation/provider/guide_ranking_provider.dart';
import 'package:travel_on_final/features/home/presentation/providers/home_provider.dart';
import 'package:travel_on_final/features/home/presentation/providers/weather_provider.dart';
import 'package:travel_on_final/features/notification/presentation/providers/notification_provider.dart';
import 'package:travel_on_final/features/reservation/presentation/providers/reservation_provider.dart';
import 'package:travel_on_final/features/review/presentation/provider/review_provider.dart';
import 'package:travel_on_final/features/search/presentation/providers/travel_provider.dart';
import 'package:travel_on_final/features/gallery/presentation/providers/gallery_provider.dart';
import 'package:travel_on_final/features/recommendation/presentation/providers/recommendation_provider.dart';
import 'package:travel_on_final/features/regional/presentation/providers/regional_provider.dart';
import 'core/providers/theme_provider.dart';

// Repositories & UseCases
import 'package:travel_on_final/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:travel_on_final/features/auth/domain/repositories/auth_repository.dart';
import 'package:travel_on_final/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:travel_on_final/features/home/data/repositories/home_repository_impl.dart';
import 'package:travel_on_final/features/home/domain/usecases/get_next_trip.dart';
import 'package:travel_on_final/features/review/data/repositories/review_repository_impl.dart';
import 'package:travel_on_final/features/search/data/repositories/travel_repositories_impl.dart';
import 'package:travel_on_final/features/gallery/data/repositories/gallery_repository.dart';
import 'package:travel_on_final/features/regional/data/repositories/regional_repository_impl.dart';

// Router
import 'package:travel_on_final/route.dart';

import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    debugPrint('Using Skia rendering');
  }
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // 네이버 맵 SDK 초기화
  await NaverMapSdk.instance.initialize(
    clientId: 'j3gnaneqmd',
    onAuthFailed: (e) => print("네이버맵 인증 실패: $e"),
  );

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_KEY'] ?? '',
  );

  // FCM 초기화 및 권한 설정
  final messaging = FirebaseMessaging.instance;
  if (Platform.isIOS) {
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Firebase App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  // Shared Preferences 초기화
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko', 'KR'),
      child: MultiProvider(
        providers: [
          Provider<FirebaseAuth>.value(value: FirebaseAuth.instance),
          Provider<FirebaseFirestore>.value(value: FirebaseFirestore.instance),
          Provider<FirebaseMessaging>.value(value: FirebaseMessaging.instance),
          Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
          Provider<GalleryRepository>(create: (_) => GalleryRepository()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => WeatherProvider()),
          ProxyProvider<FirebaseAuth, ResetPasswordUseCase>(
            update: (_, auth, __) => ResetPasswordUseCase(auth),
          ),
          ChangeNotifierProvider(
            create: (_) => TravelProvider(
              TravelRepositoryImpl(),
              auth: FirebaseAuth.instance,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => app.AuthProvider(
              context.read<FirebaseAuth>(),
              context.read<ResetPasswordUseCase>(),
              context.read<TravelProvider>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                ChatProvider(context.read<NavigationProvider>()),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                ReservationProvider(FirebaseFirestore.instance),
          ),
          ChangeNotifierProvider(
            create: (context) => ReviewProvider(
              ReviewRepositoryImpl(context.read<TravelProvider>()),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => HomeProvider(
              GetNextTrip(HomeRepositoryImpl(FirebaseFirestore.instance)),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                GalleryProvider(context.read<GalleryRepository>()),
          ),
          ChangeNotifierProvider(
            create: (_) => GuideRankingProvider(FirebaseFirestore.instance),
          ),
          ChangeNotifierProvider(
            create: (context) => NotificationProvider(
              FirebaseFirestore.instance,
              FirebaseMessaging.instance,
              context.read<NavigationProvider>(),
            ),
          ),
          ChangeNotifierProvider(create: (_) => RecommendationProvider()),
          ChangeNotifierProvider(
            create: (context) => RegionalProvider(
              RegionalRepositoryImpl(
                client: http.Client(),
              ),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(prefs),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp.router(
        title: 'Travel On',
        debugShowCheckedModeBanner: false,
        routerConfig: goRouter, // 여전히 go_router 사용
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.travelonLightBlueColor,
            brightness: Brightness.light,
            background: Colors.white,
            surface: Colors.white,
            primary: AppColors.travelonLightBlueColor,
            secondary: Colors.blueAccent,
            onSurface: Colors.black87,
            onPrimary: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(AppColors.travelonLightBlueColor),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              textStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  inherit: true,
                ),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          cardTheme: const CardTheme(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 4),
            color: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.travelonLightBlueColor,
            unselectedItemColor: Colors.grey,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.travelonBlueColor,
            brightness: Brightness.dark,
            background: const Color(0xFF1A1A1A),
            surface: const Color(0xFF2C2C2C),
            primary: AppColors.travelonBlueColor,
            secondary: Colors.blueAccent,
            onSurface: Colors.white,
            onPrimary: Colors.white,
            onBackground: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          cardTheme: CardTheme(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white70),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white70,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white70),
          ),
          dividerTheme: const DividerThemeData(
            color: Colors.white24,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(AppColors.travelonBlueColor),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              textStyle: WidgetStateProperty.all(
                const TextStyle(
                  fontWeight: FontWeight.bold,
                  inherit: true,
                ),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A1A1A),
            selectedItemColor: AppColors.travelonBlueColor,
            unselectedItemColor: Colors.grey,
            elevation: 0,
          ),
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}
