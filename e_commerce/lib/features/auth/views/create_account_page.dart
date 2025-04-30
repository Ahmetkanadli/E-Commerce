import 'package:e_commerce/features/auth/widgets/textField_widget.dart';
import 'package:e_commerce/features/auth/widgets/authentication_button.dart';
import 'package:e_commerce/features/auth/views/auth_controller.dart';
import 'package:e_commerce/core/repository/auth_repository.dart';
import 'package:e_commerce/core/api/api_client.dart';
import 'package:e_commerce/core/api/api_constants.dart';
import 'package:e_commerce/core/utils/show_notification.dart';
import 'package:e_commerce/features/auth/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthController _authController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
    final authRepository = AuthRepository(apiClient);
    _authController = AuthController(authRepository);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final l10n = AppLocalizations.of(context)!;
    
    // Validate fields
    if (_nameController.text.isEmpty) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.nameTooShort,
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    if (_emailController.text.isEmpty) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.emailRequired,
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      ShowNotification.showNotification(
        title: l10n.validationErrorTitle,
        message: l10n.passwordRequired,
        context: context,
        onPressFunction: () => Navigator.pop(context),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final success = await _authController.signup(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        context,
      );

      if (success && mounted) {
        // Başarılı kayıt sonrası login sayfasına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    width: MediaQuery.of(context).size.width*2,
                    child: Image.asset(
                      "assets/login_bubbles.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(top: 250.h, left: 20.w, right: 20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.createAccount,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.raleway(
                            fontSize: 52.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          l10n.welcomeCommunity,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 25.h),
                        TextFieldWidget(l10n.name, _nameController, false),
                        SizedBox(height: 15.h),
                        TextFieldWidget(l10n.email, _emailController, false),
                        SizedBox(height: 15.h),
                        TextFieldWidget(l10n.password, _passwordController, true),
                        SizedBox(height: 37.h),
                        AuthenticationBuuttonWidget(
                          _isLoading
                              ? l10n.loading
                              : l10n.createAccount,
                          _isLoading ? null : _handleRegister,
                        ),
                        SizedBox(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.alreadyHaveAccount,
                              style: GoogleFonts.nunitoSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w300,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                l10n.login,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF004CFF),
                                ),
                              ),
                            ),
                          ],
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
