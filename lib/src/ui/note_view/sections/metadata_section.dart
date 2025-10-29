// lib/src/ui/note_view/sections/metadata_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';

class MetadataSection extends StatelessWidget {
  const MetadataSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        return SimpleSection(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.currentNote?.createdAt != null) ...[
                _InfoRow(
                  label: 'Created',
                  value: state.formatDate(state.currentNote!.createdAt),
                ),
                const SizedBox(height: 8),
              ],
              if (state.currentNote?.updatedAt != null) ...[
                _InfoRow(
                  label: 'Last modified',
                  value: state.formatDate(state.currentNote!.updatedAt!),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}