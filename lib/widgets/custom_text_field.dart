import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String? label; // Made optional since sometimes you don't need a label
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor; // Added fillColor parameter
  final TextStyle? textStyle; // Added textStyle parameter
  final TextStyle? hintStyle; // Added hintStyle parameter

  const CustomTextField({
    Key? key,
    this.label, // Made optional
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.inputFormatters,
    this.fillColor, // Added to constructor
    this.textStyle, // Added to constructor
    this.hintStyle, // Added to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) // Only show label if provided
          Text(
            label!,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        if (label != null) const SizedBox(height: 8), // Only add spacing if label exists
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          style: textStyle, // Apply custom text style
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: hintStyle, // Apply custom hint style
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
            fillColor: fillColor, // Apply custom fill color
            filled: fillColor != null, // Enable fill when fillColor is provided
          ),
        ),
      ],
    );
  }
}

class PhoneNumberField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool enabled;

  const PhoneNumberField({
    Key? key,
    required this.label,
    this.controller,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hint: '+237 6XX XXX XXX',
      controller: controller,
      validator: validator ?? _defaultPhoneValidator,
      keyboardType: TextInputType.phone,
      prefixIcon: const Icon(Icons.phone),
      enabled: enabled,
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    
    // Remove spaces and special characters
    final cleanNumber = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Cameroon phone number validation
    if (!cleanNumber.startsWith('+237') && !cleanNumber.startsWith('237')) {
      return 'Le numéro doit commencer par +237 ou 237';
    }
    
    final phoneWithoutCountryCode = cleanNumber.startsWith('+237')
        ? cleanNumber.substring(4)
        : cleanNumber.startsWith('237')
            ? cleanNumber.substring(3)
            : cleanNumber;
    
    if (phoneWithoutCountryCode.length != 9) {
      return 'Le numéro doit contenir 9 chiffres après l\'indicatif';
    }
    
    return null;
  }
}