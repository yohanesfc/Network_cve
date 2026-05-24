import 'package:flutter/material.dart';
import '../main.dart';

class HostInputWidget extends StatelessWidget {
  final TextEditingController controller;

  const HostInputWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4DB6C8) : AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Input row ──────────────────────────────────────────
          Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.language, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    hintText: 'hostname or IP address...',
                    hintStyle: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                onPressed: () => controller.clear(),
              ),
            ],
          ),

          // ── Divider ────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[800] : Colors.grey[200],
          ),

          // ── Quick chips ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.bolt, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Quick:',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 8),
                _chip('google.com', color),
                const SizedBox(width: 6),
                _chip('1.1.1.1', color),
                const SizedBox(width: 6),
                _chip('8.8.8.8', color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return GestureDetector(
      onTap: () => controller.text = label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
