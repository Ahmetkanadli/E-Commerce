import 'package:e_commerce/authentication_pages/password_screeen.dart';
import 'package:e_commerce/authentication_pages/textField_widget.dart';
import 'package:e_commerce/authentication_pages/widget/authentication_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Image.asset(
              "assets/login_bubbles.png",
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 499.h, left: 20.w,right: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("LOGIN",
                    textAlign: TextAlign.start,
                    style: GoogleFonts.raleway(
                        fontSize: 52.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                SizedBox(height: 2.h),
                Text("Good to see you back!",
                    textAlign: TextAlign.start,
                    style: GoogleFonts.nunitoSans(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w300,
                        color: Colors.black)),
                SizedBox(height: 25.h),
                TextFieldWidget('Email', _emailController, false),
                SizedBox(height: 37.h),
                AuthenticationBuuttonWidget('Next', (){
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PasswordScreeen()));
                }),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
