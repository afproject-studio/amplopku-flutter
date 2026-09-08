import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? obscureText : false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(widget.prefixIcon),

        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    obscureText = !obscureText;
                  });
                },
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              )
            : null,
      ),
    );
  }
}