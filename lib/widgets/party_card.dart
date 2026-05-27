import 'package:flutter/material.dart';
import '../models/party.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class PartyCard extends StatelessWidget {
  final Party party;
  final int vehicleCount;
  final int tripCount;
  final double credit;
  final double debit;
  final VoidCallback onTap;
  final VoidCallback onPdf;

  const PartyCard({
    required this.party,
    required this.vehicleCount,
    required this.tripCount,
    required this.credit,
    required this.debit,
    required this.onTap,
    required this.onPdf,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final balance = credit - debit;
    final balanceColor = balance >= 0 ? AppColors.creditText : AppColors.debitText;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with initials
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(180),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      party.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Party info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          party.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (party.phone != null && party.phone!.isNotEmpty)
                          Text(
                            party.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // PDF button
                  IconButton(
                    onPressed: onPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    color: Colors.red,
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatWidget(label: 'Vehicles', value: '$vehicleCount'),
                  _StatWidget(label: 'Trips', value: '$tripCount'),
                  _StatWidget(
                    label: 'CR',
                    value: Formatters.formatAmount(credit),
                    color: AppColors.creditText,
                  ),
                  _StatWidget(
                    label: 'DR',
                    value: Formatters.formatAmount(debit),
                    color: AppColors.debitText,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Balance row
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: balance >= 0 ? AppColors.creditBg : AppColors.debitBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Balance: ${Formatters.formatAmount(balance.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: balanceColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatWidget({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
