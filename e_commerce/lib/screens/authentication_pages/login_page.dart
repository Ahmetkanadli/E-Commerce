import 'package:e_commerce/authentication_pages/password_screeen.dart';
import 'package:e_commerce/authentication_pages/textField_widget.dart';
import 'package:e_commerce/authentication_pages/widget/authentication_button.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/utils/show_notification.dart';
import 'package:e_commerce/features/auth/controllers/auth_controller.dart';
import 'package:e_commerce/features/auth/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: '');
    final authRepository = AuthRepository(apiClient);
    _authController = AuthController(authRepository);
  }

  void _handleNext() {
    if (_emailController.text.isEmpty) {
      ShowNotification.showNotification(
        title: 'Validation Error',
        message: 'Please enter your email',
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      return;
    }

    // Basic email validation
    if (!_emailController.text.contains('@')) {
      ShowNotification.showNotification(
        title: 'Validation Error',
        message: 'Please enter a valid email address',
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PasswordScreeen(
          email: _emailController.text,
          authController: _authController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authController,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.asset(
                    "assets/login_bubbles.png",
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 499.h, left: 20.w, right: 20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LOGIN",
                        textAlign: TextAlign.start,
                        style: GoogleFonts.raleway(
                          fontSize: 52.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Good to see you back!",
                        textAlign: TextAlign.start,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 25.h),
                      TextFieldWidget('Email', _emailController, false),
                      SizedBox(height: 37.h),
                      Consumer<AuthController>(
                        builder: (context, controller, child) {
                          if (controller.error != null) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: Text(
                                controller.error!,
                                style: TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Consumer<AuthController>(
                        builder: (context, controller, child) {
                          return AuthenticationBuuttonWidget(
                            controller.isLoading ? 'Loading...' : 'Next',
                            controller.isLoading ? null : _handleNext,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
