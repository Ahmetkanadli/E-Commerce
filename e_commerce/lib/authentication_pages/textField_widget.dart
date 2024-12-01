import 'package:flutter/material.dart';

Widget TextFieldWidget(
    String labelText, TextEditingController controller, bool obsecureText) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.3),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.0)),
        borderSide: BorderSide(
          color: Color(0xFFF8F8F8),
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.0)),
        borderSide: BorderSide(
          color: Color(0xFFF8F8F8),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.0)),
        borderSide: BorderSide(
          color: Color(0xFFF8F8F8),
        ),
      ),
      fillColor: Colors.grey.withOpacity(0.1),
      filled: true,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
    ),
    obscureText: obsecureText,
  );
}
