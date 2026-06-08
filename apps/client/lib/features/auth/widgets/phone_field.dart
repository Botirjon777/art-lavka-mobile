import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Phone input with a fixed `+998` prefix and a `(XX) XXX-XX-XX` mask over the
/// 9 national digits (SPEC §8). The editable text holds only the formatted
/// national number; build E.164 from it via `Validators.normalizePhone`.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label,
    this.errorText,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [_UzPhoneFormatter()],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '+998 ',
        hintText: '(90) 123-45-67',
        errorText: errorText,
        // Reserve the error line so layout never jumps (SPEC §10).
        helperText: ' ',
      ),
    );
  }
}

/// Formats up to 9 digits as `(XX) XXX-XX-XX` as the user types.
class _UzPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) digits = digits.substring(0, 9);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      switch (i) {
        case 0:
          buffer.write('(');
        case 2:
          buffer.write(') ');
        case 5 || 7:
          buffer.write('-');
      }
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
