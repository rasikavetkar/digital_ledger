import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/party_provider.dart';
import '../providers/transaction_provider.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.number),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, child) {
          final partyProvider = context.read<PartyProvider>();
          
          // Get transactions for this vehicle
          final transactions = txProvider.transactions
              .where((t) => t.vehicleId == vehicle.id)
              .toList();
          
          // Get party info
          final party = partyProvider.getPartyById(vehicle.partyId);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Vehicle Info Card
                Container(
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.number,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Type: ${vehicle.type}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      if (party != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Owner: ${party.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Transactions List
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: transactions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No transactions for this vehicle',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transactions (${transactions.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                              itemBuilder: (_, i) {
                                final tx = transactions[i];
                                return ListTile(
                                  title: Text(
                                    '?${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: tx.type == 'credit' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    tx.type == 'credit' ? 'Credit' : 'Debit',
                                    style: const TextStyle(color: Colors.white54),
                                  ),
                                  trailing: Text(
                                    '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
