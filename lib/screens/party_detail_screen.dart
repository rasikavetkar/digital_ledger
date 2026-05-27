import 'package:flutter/material.dart';
import '../models/party.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/transaction_tile.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class PartyDetailScreen extends StatelessWidget {
  final Party party;
  final List<Vehicle> vehicles;
  final List<Transaction> transactions;

  const PartyDetailScreen({
    required this.party,
    required this.vehicles,
    required this.transactions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final credit = transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final debit = transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = credit - debit;

    return Scaffold(
      appBar: AppBar(
        title: Text(party.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
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
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                party.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (party.phone != null && party.phone!.isNotEmpty)
                                Text(
                                  party.phone!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Vehicles',
                          value: '${vehicles.length}',
                        ),
                        _StatItem(
                          label: 'Trips',
                          value: '${transactions.length}',
                        ),
                        _StatItem(
                          label: 'Credit',
                          value: Formatters.formatAmount(credit),
                          color: AppColors.creditText,
                        ),
                        _StatItem(
                          label: 'Debit',
                          value: Formatters.formatAmount(debit),
                          color: AppColors.debitText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: balance >= 0
                            ? AppColors.creditBg
                            : AppColors.debitBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Net Balance: ${Formatters.formatAmount(balance.abs())}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0
                              ? AppColors.creditText
                              : AppColors.debitText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Vehicles section
            const Text(
              'Vehicles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (vehicles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No vehicles',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final vehicleTransactions =
                      transactions.where((t) => t.vehicleId == vehicle.id).toList();

                  return VehicleCard(
                    vehicle: vehicle,
                    ownerName: party.name,
                    tripCount: vehicleTransactions.length,
                    totalLoads: vehicleTransactions.fold(
                      0,
                      (sum, t) => sum + t.quantity,
                    ),
                    onTap: () {},
                  );
                },
              ),
            const SizedBox(height: 20),

            // Transactions section
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No transactions',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final vehicle = vehicles.firstWhere(
                    (v) => v.id == transaction.vehicleId,
                    orElse: () => Vehicle(
                      id: -1,
                      number: 'Unknown',
                      partyId: party.id!,
                      type: 'Unknown',
                    ),
                  );

                  return TransactionTile(
                    transaction: transaction,
                    vehicle: vehicle,
                    party: party,
                    onDelete: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
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
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

