import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/party_card.dart';
import '../widgets/add_party_sheet.dart';
import 'party_detail_screen.dart';

class PartiesScreen extends StatelessWidget {
  const PartiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PartyProvider, TransactionProvider>(
      builder: (context, partyProvider, transactionProvider, _) {
        final vehicleProvider = context.read<VehicleProvider>();

        return Column(
          children: [
            // Header with party count and add button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parties',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${partyProvider.parties.length} parties',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPartySheet(context, partyProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Party'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Parties list
            Expanded(
              child: partyProvider.parties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No parties yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPartySheet(context, partyProvider),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Party'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: partyProvider.parties.length,
                      itemBuilder: (context, index) {
                        final party = partyProvider.parties[index];
                        final vehicles = vehicleProvider.getVehiclesForParty(party.id!);
                        final transactions = transactionProvider
                            .getTransactionsForParty(party.id!);
                        final credit = transactions
                            .where((t) => t.type == 'credit')
                            .fold(0.0, (sum, t) => sum + t.amount);
                        final debit = transactions
                            .where((t) => t.type == 'debit')
                            .fold(0.0, (sum, t) => sum + t.amount);

                        return PartyCard(
                          party: party,
                          vehicleCount: vehicles.length,
                          tripCount: transactions.length,
                          credit: credit,
                          debit: debit,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PartyDetailScreen(
                                  party: party,
                                ),
                              ),
                            );
                          },
                          onPdf: () {
                            // TODO: Generate PDF
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF generation coming soon')),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showAddPartySheet(BuildContext context, PartyProvider partyProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddPartySheet(
        onSave: (name, phone) {
          partyProvider.addParty(name, phone);
        },
      ),
    );
  }
}
