import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/utils/show_notification.dart';
import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/core/repository/auth_repository.dart';
import 'package:e_commerce/features/auth/views/password_screeen.dart';
import 'package:e_commerce/features/auth/widgets/textField_widget.dart';
import 'package:e_commerce/features/auth/widgets/authentication_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    final authRepository = AuthRepository(apiClient);
    _authController = AuthController(authRepository);
  }

  void _handleNext() {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.emailRequired,
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      return;
    }

    // Basic email validation
    if (!_emailController.text.contains('@')) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.invalidEmail,
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
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider.value(
      value: _authController,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SingleChildScrollView(
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
                      padding:
                          EdgeInsets.only(top: 499.h, left: 20.w, right: 20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.loginTitle,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.raleway(
                              fontSize: 52.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            l10n.welcomeBack,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 25.h),
                          TextFieldWidget(l10n.email, _emailController, false),
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
                                l10n.next,
                                _handleNext,
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
            // Back Button
            Positioned(
              top: 50.h,
              left: 20.w,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
