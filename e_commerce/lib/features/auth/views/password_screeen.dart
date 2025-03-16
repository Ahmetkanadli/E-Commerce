import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/features/activity/views/activity_screen.dart';
import 'package:e_commerce/core/utils/show_notification.dart';
import 'package:e_commerce/features/auth/widgets/textField_widget.dart';
import 'package:e_commerce/features/auth/widgets/authentication_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PasswordScreeen extends StatefulWidget {
  final String email;
  final AuthController authController;

  const PasswordScreeen({
    Key? key,
    required this.email,
    required this.authController,
  }) : super(key: key);

  @override
  State<PasswordScreeen> createState() => _PasswordScreeenState();
}

class _PasswordScreeenState extends State<PasswordScreeen> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.passwordRequired,
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      return;
    }

    final success = await widget.authController.login(
      widget.email,
      _passwordController.text,
      context,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ActivityScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
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
                          l10n.password,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.raleway(
                            fontSize: 52.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.enterPassword,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 25.h),
                        TextFieldWidget(
                            l10n.password, _passwordController, true),
                        SizedBox(height: 37.h),
                        if (widget.authController.error != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Text(
                              widget.authController.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        AuthenticationBuuttonWidget(
                          widget.authController.isLoading
                              ? l10n.loading
                              : l10n.login,
                          widget.authController.isLoading ? null : _handleLogin,
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
    );
  }
}
