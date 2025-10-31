// lib/src/ui/note_view/widgets/simple_section.dart
import 'package:flutter/material.dart';
import '../../../constants/spacing.dart';

class SimpleSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? minHeight;
  final bool showBorder;
  final Color? backgroundColor;
  
  const SimpleSection({
    super.key,
    required this.child,
    this.padding,
    this.minHeight,
    this.showBorder = false,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding ?? AppSpacing.sectionPadding,
      decoration: showBorder ? BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? Colors.white,
      ) : BoxDecoration(
        color: backgroundColor,
      ),
      child: child,
    );
    
    return content;
  }
}