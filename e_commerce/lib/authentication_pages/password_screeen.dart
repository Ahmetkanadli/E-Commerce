import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PasswordScreeen extends StatefulWidget {
  const PasswordScreeen({super.key});

  @override
  State<PasswordScreeen> createState() => _PasswordScreeenState();
}

class _PasswordScreeenState extends State<PasswordScreeen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Image.asset(
                'assets/login_bubbles.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 156.h, left: 20, right: 20),
              child: Center(
                child: Column(
                  children: [
                    /*
                    Icon(CupertinoIcons.person, size: 100, color: Colors.black),
                    SizedBox(height: 70.h),
                    Text('HELLO',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.raleway(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),
                    SizedBox(height: 46.h),
                     */
                    SizedBox(height: 220.h,),
                    Text('Type your password',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.raleway(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black)),
                    SizedBox(height: 30.h),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: PinCodeTextField(
                        controller: _pinController,
                        appContext: context,
                        length: 8,
                        obscureText: true,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.circle,
                          borderRadius: BorderRadius.circular(5),
                          fieldHeight: 30.w,
                          fieldWidth: 30.w,
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          activeColor: Colors.green.shade700,
                          selectedColor: Colors.blue.shade700,
                          inactiveColor: Colors.grey,
                        ),
                        animationDuration: Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent,
                        enableActiveFill: true,
                        onChanged: (value) {
                          if (mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}