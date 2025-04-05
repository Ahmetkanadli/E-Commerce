import 'dart:ui';
import 'package:e_commerce/features/main_screen.dart';
import 'package:e_commerce/features/onboarding/views/splash_screen.dart';
import 'package:e_commerce/core/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/repository/auth_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            AuthRepository(
              ApiClient(baseUrl: ApiConstants.baseUrl),
            ),
          )..checkAuthStatus(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'E-Commerce',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: localeProvider.locale,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/main': (context) => const MainScreen(),
              '/login': (context) => const Scaffold(body: Center(child: Text('Login Screen'))),
            },
          ),
        );
      },
    );
  }
}
