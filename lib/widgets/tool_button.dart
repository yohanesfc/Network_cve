import 'package:flutter/material.dart';
import '../main.dart';

class ToolButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isHighlighted;

  const ToolButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF4DB6C8)
                  : AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
