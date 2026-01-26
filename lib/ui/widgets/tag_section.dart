import 'package:flutter/material.dart';

import '../../data/local/app_database.dart';

// class TagSection extends StatelessWidget {
//   final String title;
//   final List<ContextTag> tags;
//   final List<int> selectedIds;
//   final void Function(int tagId) onToggle;
//   final VoidCallback onAdd;
//
//   const TagSection({
//     super.key,
//     required this.title,
//     required this.tags,
//     required this.selectedIds,
//     required this.onToggle,
//     required this.onAdd,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontSize: 16)),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             ...tags.map((tag) {
//               final isSelected = selectedIds.contains(tag.id);
//               return ChoiceChip(
//                 label: Text(tag.name),
//                 selected: isSelected,
//                 onSelected: (_) => onToggle(tag.id),
//               );
//             }),
//             ActionChip(
//               label: const Text('+'),
//               onPressed: onAdd,
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }


import 'dart:ui';

class TagSection extends StatelessWidget {
  final String title;
  final List<ContextTag> tags;
  final List<int> selectedIds;
  final void Function(int tagId) onToggle;
  final VoidCallback onAdd;

  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.selectedIds,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Color(0xFFC0C0C0),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) {
              final isSelected = selectedIds.contains(tag.id);
              return _PixelTag(
                text: tag.name,
                selected: isSelected,
                onTap: () => onToggle(tag.id),
              );
            }),
            _PixelTag(
              text: '+',
              selected: false,
              onTap: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}
class _PixelTag extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _PixelTag({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEDEDED)
              : const Color(0xFF1A1A1A),
          border: Border.all(
            color: selected
                ? Colors.white
                : const Color(0xFF555555),
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'DotGothic',
            fontSize: 16,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
