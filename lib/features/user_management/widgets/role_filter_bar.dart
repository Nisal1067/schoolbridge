import 'package:flutter/material.dart';

class RoleFilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const RoleFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const List<String> filters = ['All', 'Students', 'Teachers', 'Staff'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () => onFilterChanged(filter),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
