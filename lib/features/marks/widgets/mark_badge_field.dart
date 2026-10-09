import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/mark_record.dart';

/// Colours for each grade band (background, text). Tweak here to match the
/// final Figma palette.
class MarkColors {
  const MarkColors._();

  static const empty = (bg: Color(0xFFF3F4F6), fg: Color(0xFF9CA3AF));

  static ({Color bg, Color fg}) of(MarkBand band) => switch (band) {
    MarkBand.a => (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF166534)),
    MarkBand.b => (bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1E40AF)),
    MarkBand.c => (bg: const Color(0xFFE0F2FE), fg: const Color(0xFF075985)),
    MarkBand.s => (bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E)),
    MarkBand.w => (bg: const Color(0xFFFEE2E2), fg: const Color(0xFF991B1B)),
  };
}

/// Accepts whole numbers from 0 to 100 only, with no leading zeros.
class _MarkInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text.length > 1 && text.startsWith('0')) return oldValue;
    final value = int.tryParse(text);
    if (value == null || value > MarkGrading.maxMark) return oldValue;
    return newValue;
  }
}

/// The 60 x 24 mark pill from the design, editable in place. Its colour
/// follows the grade band of the entered mark.
class MarkBadgeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLast;
  final ValueChanged<String>? onChanged;

  const MarkBadgeField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.isLast = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final mark = int.tryParse(value.text);
        final colors = mark == null
            ? MarkColors.empty
            : MarkColors.of(MarkGrading.bandFor(mark));
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 60,
          height: 24,
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: isLast
                ? TextInputAction.done
                : TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MarkInputFormatter(),
            ],
            maxLength: 3,
            style: TextStyle(
              color: colors.fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            cursorColor: colors.fg,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              counterText: '',
              hintText: '—',
              hintStyle: TextStyle(color: colors.fg, fontSize: 13),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}
