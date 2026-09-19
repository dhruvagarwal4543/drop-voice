import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Tactical text input field.
class DvTextField extends StatelessWidget {
  const DvTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.maxLength,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(labelText!.toUpperCase(), style: Dv.label(color: Dv.ash)),
          const SizedBox(height: Dv.s8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          maxLength: maxLength,
          style: Dv.monoLarge(size: 18, color: Dv.white),
          cursorColor: Dv.green,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '', // Hide default counter
            errorText: errorText,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dv.s16,
              vertical: Dv.s20,
            ),
          ),
        ),
      ],
    );
  }
}
