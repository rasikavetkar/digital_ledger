import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/party_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/transaction_tile.dart';
import '../utils/theme.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late TextEditingController _searchController;
  String _filterType = 'All'; // All, Credit, Debit

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() { 
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final vehicleProvider = context.read<VehicleProvider>();
        final partyProvider = context.read<PartyProvider>();

        var filteredTransactions = transactionProvider.transactions;

        // Apply type filter
        if (_filterType == 'Credit') {
          filteredTransactions = filteredTransactions
              .where((t) => t.type == 'credit')
              .toList();
        } else if (_filterType == 'Debit') {
          filteredTransactions = filteredTransactions
              .where((t) => t.type == 'debit')
              .toList();
        }

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.trim().toLowerCase();
          filteredTransactions = filteredTransactions
              .where((t) {
                final vehicle = vehicleProvider.getVehicleById(t.vehicleId);
                if (vehicle == null) return false;
                
                // Search by vehicle number (last 4 digits exact match if 4 digits entered, substring otherwise)
                bool vehicleMatch = false;
                final isFourDigits = RegExp(r'^\d{4}$').hasMatch(query);
                if (isFourDigits) {
                  if (vehicle.number.length >= 4) {
                    final lastFour = vehicle.number.substring(vehicle.number.length - 4);
                    vehicleMatch = (lastFour.toLowerCase() == query);
                  }
                } else {
                  vehicleMatch = vehicle.number.toLowerCase().contains(query);
                }
                
                // Search by party/owner name
                final party = partyProvider.getPartyById(vehicle.partyId);
                final partyMatch = party?.name.toLowerCase().contains(query) ?? false;
                
                return vehicleMatch || partyMatch;
              })
              .toList();
        }

        return Column(
          children: [
            // Summary cards - Credit and Debit side by side
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Credit',
                          value: transactionProvider.totalCredit,
                          bgColor: AppColors.creditBg,
                          textColor: AppColors.creditText,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          label: 'Total Debit',
                          value: transactionProvider.totalDebit,
                          bgColor: AppColors.debitBg,
                          textColor: AppColors.debitText,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Balance',
                          value: transactionProvider.balance,
                          bgColor: Colors.blue.shade50,
                          textColor: AppColors.balanceText,
                          icon: Icons.wallet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search by vehicle number or party name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: ['All', 'Credit', 'Debit'].map((filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: _filterType == filter,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = filter;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Transactions list
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No entries found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first entry',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        final vehicle = vehicleProvider.getVehicleById(transaction.vehicleId);
                        final party = vehicle != null
                            ? partyProvider.getPartyById(vehicle.partyId)
                            : null;

                        return TransactionTile(
                          transaction: transaction,
                          vehicle: vehicle,
                          party: party,
                          onDelete: () async {
                            await transactionProvider.deleteTransaction(transaction.id!);
                            if (context.mounted) {
                              context.read<VehicleProvider>().loadVehicles();
                              context.read<PartyProvider>().loadParties();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Entry deleted')),
                              );
                            }
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
}
