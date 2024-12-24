import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

Widget AuthenticationBuuttonWidget(String text, Function? onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF004CFF),
      minimumSize: Size(double.infinity, 61.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
    ),
    onPressed: onPressed == null ? null : () => onPressed(),
    child: Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: 22.sp,
        fontWeight: FontWeight.w300,
        color: const Color(0xFFF3F3F3),
      ),
    ),
  );
}
