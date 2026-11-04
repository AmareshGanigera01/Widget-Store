import 'package:flutter/material.dart';

/// Icons are stored as string keys (not code points) so configs stay
/// portable and icon tree-shaking keeps working.
const Map<String, IconData> appIcons = {
  'alarm': Icons.alarm,
  'sports_cricket': Icons.sports_cricket,
  'edit_note': Icons.edit_note,
  'checklist': Icons.checklist,
  'book': Icons.menu_book,
  'science': Icons.science,
  'medicine': Icons.medication,
  'study': Icons.auto_stories,
  'work': Icons.work_outline,
  'custom': Icons.notifications_active_outlined,
};

IconData iconFor(String key) => appIcons[key] ?? Icons.widgets_outlined;

/// Swatches offered by the color picker and new-notebook dialog.
const List<int> paletteColors = [
  0xFF6750A4,
  0xFF5E35B1,
  0xFF0061A4,
  0xFF00897B,
  0xFF2E7D32,
  0xFFF9A825,
  0xFFEF6C00,
  0xFFB3261E,
  0xFFAD1457,
  0xFF455A64,
];
