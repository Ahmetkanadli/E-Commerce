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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Image.asset(
                  "assets/Bubbles.png",
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding:  EdgeInsets.only(top: 140.h, left: 30.0),
                child: Column(
                  children: [
                    Text("CREATE \nACCOUNT",
                        textAlign: TextAlign.start,
                        style: GoogleFonts.raleway(
                            fontSize: 50.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black)),

                  ],
                ),
              ),
              Padding(
                padding:  EdgeInsets.only(top: 320.h, left: 30.0),
                child: SizedBox(
                    child: SizedBox(
                        width: 90.w, child: Image.asset('assets/camera.png'))),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.h),
            child: Column(
              children: [
                TextFieldWidget('Email', _emailController, false),
                const SizedBox(height: 16.0),
                TextFieldWidget('Password', _passwordController, true),
                SizedBox(height: 50.h),
                AuthenticationBuuttonWidget("Done", (){})
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
