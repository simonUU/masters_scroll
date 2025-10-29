// lib/src/ui/note_view/widgets/section_card.dart
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? headerColor;
  final Widget child;
  final Widget? trailing;
  final double? minHeight;
  
  const SectionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.headerColor,
    this.trailing,
    this.minHeight,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor ?? Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: _getIconColor()),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: _getTextColor(),
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(minHeight: minHeight ?? 100),
            child: child,
          ),
        ],
      ),
    );
  }
  
  Color _getIconColor() {
    if (headerColor == null) return Colors.grey[600]!;
    if (headerColor == Colors.grey[100]) return Colors.grey[600]!;
    if (headerColor == Colors.blue[50]) return Colors.blue[600]!;
    if (headerColor == Colors.green[50]) return Colors.green[600]!;
    return Colors.grey[600]!;
  }
  
  Color _getTextColor() {
    if (headerColor == null) return Colors.grey[700]!;
    if (headerColor == Colors.grey[100]) return Colors.grey[700]!;
    if (headerColor == Colors.blue[50]) return Colors.blue[700]!;
    if (headerColor == Colors.green[50]) return Colors.green[700]!;
    return Colors.grey[700]!;
  }
}