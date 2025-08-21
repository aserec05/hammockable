// widgets/label_icons.dart
import 'package:flutter/material.dart';

class LabelIconsWidget extends StatelessWidget {
  final List<Map<String, dynamic>>? labels;
  final int maxIcons;
  final double iconSize;

  const LabelIconsWidget({
    super.key,
    required this.labels,
    this.maxIcons = 5,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (labels == null || labels!.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleLabels = labels!.take(maxIcons).toList();
    final hiddenCount = labels!.length - visibleLabels.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleLabels.map((label) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Tooltip(
              message: label['name'] ?? 'Inconnu',
              child: Icon(
                _getIconData(label['icon']),
                size: iconSize,
                color: _getColor(label['color']),
              ),
            ),
          );
        }),
        if (hiddenCount > 0)
          Tooltip(
            message: '$hiddenCount autres caractéristiques',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$hiddenCount',
                style: TextStyle(
                  fontSize: iconSize - 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getIconData(dynamic iconCode) {
    if (iconCode is int) {
      return IconData(iconCode, fontFamily: 'MaterialIcons');
    }
    return Icons.label; // Icône par défaut
  }

  Color _getColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    }
    return Colors.grey; // Couleur par défaut
  }
}