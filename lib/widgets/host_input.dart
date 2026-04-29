import 'package:flutter/material.dart';
import '../main.dart';

class HostInputWidget extends StatelessWidget {
  final TextEditingController controller;

  const HostInputWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    hintText: 'Enter hostname or IP...',
                    hintStyle: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                onPressed: () => controller.clear(),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: null,
                      dropdownColor: Colors.white,
                      hint: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'Select host',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'google.com',
                          child: Text(
                            'google.com',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '1.1.1.1',
                          child: Text(
                            '1.1.1.1 (Cloudflare)',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        DropdownMenuItem(
                          value: '8.8.8.8',
                          child: Text(
                            '8.8.8.8 (Google DNS)',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.text = val;
                      },
                      isExpanded: true,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
