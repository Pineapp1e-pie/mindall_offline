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
  final VoidCallback? onAdd;
  final bool editMode;
  final void Function(int tagId)? onDelete;
  final Color? moodColor;

  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.selectedIds,
    required this.onToggle,
    this.onAdd,
    this.editMode = false,
    this.onDelete,
    this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    final deleteColor = moodColor ?? Colors.white70;
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
          runSpacing: editMode ? 16 : 8,
          children: [
            ...tags.map((tag) {
              final isSelected = selectedIds.contains(tag.id);
              if (editMode) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _PixelTag(
                      text: tag.name,
                      selected: isSelected,
                      onTap: () => onDelete?.call(tag.id),
                    ),
                    Positioned(
                      top: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1511),
                            shape: BoxShape.circle,
                            border: Border.all(color: deleteColor),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 10,
                            color: deleteColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return _PixelTag(
                text: tag.name,
                selected: isSelected,
                onTap: () => onToggle(tag.id),
              );
            }),
            if (onAdd != null && !editMode)
              _PixelTag(
                text: '+',
                selected: false,
                onTap: onAdd!,
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
        constraints: const BoxConstraints(minWidth: 100), // Минимальная ширина для температур
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
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
        child: Center(
          child: _buildTextContent(),
        ),
      ),
    );
  }

  // Разбираем текст на две части, если есть перенос строки
  Widget _buildTextContent() {
    if (text.contains('\n')) {
      final parts = text.split('\n');
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parts[0], // "Холодно"
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 16,
              color: selected ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            parts[1], // "-25°C … -10°C"
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DotGothic',
              fontSize: 14,
              color: selected ? Colors.black54 : Colors.white70,
            ),
          ),
        ],
      );
    } else {
      // Обычный текст без переноса
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'DotGothic',
          fontSize: 16,
          color: selected ? Colors.black : Colors.white,
        ),
      );
    }
  }
}
