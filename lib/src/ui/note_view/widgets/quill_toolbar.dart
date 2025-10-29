// lib/src/ui/note_view/widgets/quill_toolbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomQuillToolbar extends StatelessWidget {
  final QuillController controller;
  
  const CustomQuillToolbar({
    Key? key,
    required this.controller,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.bold,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_bold,
              tooltip: 'Bold',
            ),
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.italic,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_italic,
              tooltip: 'Italic',
            ),
          ),
          const SizedBox(width: 8),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.ul,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
            ),
          ),
          QuillToolbarToggleStyleButton(
            controller: controller,
            attribute: Attribute.ol,
            options: const QuillToolbarToggleStyleButtonOptions(
              iconData: Icons.format_list_numbered,
              tooltip: 'Numbered List',
            ),
          ),
        ],
      ),
    );
  }
}