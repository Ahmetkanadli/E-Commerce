import 'package:e_commerce/features/auth/views/create_account_page.dart';
import 'package:e_commerce/features/auth/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 161.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 134.w),
            child: Image.asset("assets/shoppie_logo.png"),
          ),
          SizedBox(height: 50.h),
          Text(
            l10n.appName,
            style: GoogleFonts.raleway(
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            l10n.welcomeMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              fontSize: 19.sp,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 86.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004CFF),
              minimumSize: Size(343.w, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            onPressed: () {
              /// TODO Buraya Push named yapısı kurulacak
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateAccountPage()));
            },
            child: Text(
              l10n.createAccount,
              style: GoogleFonts.nunitoSans(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          SizedBox(height: 30.h),
          GestureDetector(
            onTap: () {
              /// TODO Buraya Push named yapısı kurulacak
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.alreadyHaveAccount,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(width: 15.w),
                Image.asset("assets/left.png", width: 30.w, height: 30.h),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
