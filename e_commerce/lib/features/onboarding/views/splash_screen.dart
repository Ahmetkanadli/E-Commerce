import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/core/repository/auth_repository.dart';
import 'package:e_commerce/features/activity/views/activity_screen.dart';
import 'package:e_commerce/features/onboarding/views/welcome.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize AuthController
    final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    final authRepository = AuthRepository(apiClient);
    _authController = AuthController(authRepository);

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check authentication status
    await _authController.checkAuthStatus();

    if (!mounted) return;

    if (_authController.token != null) {
      // User is authenticated, navigate to ActivityScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ActivityScreen()),
      );
    } else {
      // User is not authenticated, navigate to WelcomePage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 84, 64, 140),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "SHOPPE",
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 31.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
