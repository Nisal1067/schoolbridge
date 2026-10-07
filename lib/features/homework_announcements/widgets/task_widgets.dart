import 'package:flutter/material.dart';

/// Colours taken from the SchoolBridge Figma file (teacher "Tasks" flow).
class TaskColors {
  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0xFFDBEAFE);
  static const Color background = Color(0xFFF3F4F6);
  static const Color ink = Color(0xFF111827);
  static const Color grey = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenSoft = Color(0xFFDCFCE7);
  static const Color red = Color(0xFFEF4444);
  static const Color redSoft = Color(0xFFFEE2E2);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFEF3C7);
}

const List<String> kSubjects = [
  'Mathematics',
  'Science',
  'English',
  'History',
  'Geography',
  'ICT',
  'Sinhala',
  'Tamil',
  'Religion',
  'Art',
];

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "05 Sep"
String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';

/// "15 Sep 2026"
String longDate(DateTime d) => '${shortDate(d)} ${d.year}';

/// "Today", "Yesterday" or "10 Sep".
String relativeDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return shortDate(d);
}

InputDecoration taskInputDecoration(String hint) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: TaskColors.grey, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(TaskColors.border),
    enabledBorder: border(TaskColors.border),
    focusedBorder: border(TaskColors.blue),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: TaskColors.ink,
        ),
      ),
    );
  }
}

/// White, rounded dropdown that matches the Figma form fields.
class TaskDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const TaskDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaskColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, color: TaskColors.grey),
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  style: const TextStyle(color: TaskColors.grey, fontSize: 14),
                ),
          style: const TextStyle(fontSize: 15, color: TaskColors.ink),
        ),
      ),
    );
  }
}

/// Homework | Announcements segmented control.
class TaskTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const TaskTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? TaskColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == selected ? Colors.white : TaskColors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded box with a dashed border. Used for "+ Add ..." and the upload box.
class DashedBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color fill;
  final EdgeInsetsGeometry padding;

  const DashedBox({
    super.key,
    required this.child,
    this.onTap,
    this.color = TaskColors.blue,
    this.fill = TaskColors.blueSoft,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: color, fill: fill),
        child: Container(
          width: double.infinity,
          padding: padding,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final Color fill;
  const _DashedBorderPainter({required this.color, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, Paint()..color = fill);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), stroke);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.fill != fill;
}

class TaskPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const TaskPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: TaskColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: TaskColors.blue.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Small rounded label, e.g. "Mathematics", "Active", "All Students".
class TaskChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const TaskChip({
    super.key,
    required this.text,
    this.background = TaskColors.blueSoft,
    this.foreground = TaskColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Shared AppBar for pages pushed from the Tasks tab.
PreferredSizeWidget taskAppBar(String title) => AppBar(
  backgroundColor: Colors.white,
  foregroundColor: TaskColors.ink,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  title: Text(
    title,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
  ),
);

void showTaskSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
