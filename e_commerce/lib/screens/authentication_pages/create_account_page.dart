import 'package:e_commerce/authentication_pages/textField_widget.dart';
import 'package:e_commerce/authentication_pages/widget/authentication_button.dart';
import 'package:e_commerce/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      "CREATE ACCOUNT",
                      textAlign: TextAlign.start,
                      style: GoogleFonts.raleway(
                        fontSize: 52.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Welcome to our community!",
                      textAlign: TextAlign.start,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 25.h),
                    // Your existing form fields and buttons
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
