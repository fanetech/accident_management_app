import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
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

  const CustomTextField({
    Key? key,
    required this.label,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorMaxLines: 2,
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
