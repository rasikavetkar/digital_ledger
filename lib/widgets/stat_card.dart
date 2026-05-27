import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class StatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const StatCard({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withAlpha(180),
                ),
              ),
              Icon(icon, color: textColor.withAlpha(180), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatAmount(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
