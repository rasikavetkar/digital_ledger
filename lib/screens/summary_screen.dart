import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/party_provider.dart';
import '../models/party.dart';
import '../widgets/stat_card.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final partyProvider = context.read<PartyProvider>();

        // Calculate total loads
        final totalLoads = transactionProvider.transactions
            .fold(0, (sum, t) => sum + t.quantity);

        // Get party-wise balance
        final partyBalances = <Map<String, dynamic>>[];
        for (var party in partyProvider.parties) {
          final credit = transactionProvider
              .getTransactionsForParty(party.id!)
              .where((t) => t.type == 'credit')
              .fold(0.0, (sum, t) => sum + t.amount);
          final debit = transactionProvider
              .getTransactionsForParty(party.id!)
              .where((t) => t.type == 'debit')
              .fold(0.0, (sum, t) => sum + t.amount);

          partyBalances.add({
            'party': party,
            'credit': credit,
            'debit': debit,
            'balance': credit - debit,
          });
        }

        // Sort by balance descending
        partyBalances.sort((a, b) => (b['balance'] as double)
            .compareTo(a['balance'] as double));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall stats grid
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                children: [
                  StatCard(
                    label: 'Total Credit',
                    value: transactionProvider.totalCredit,
                    bgColor: AppColors.creditBg,
                    textColor: AppColors.creditText,
                    icon: Icons.arrow_downward,
                  ),
                  StatCard(
                    label: 'Total Debit',
                    value: transactionProvider.totalDebit,
                    bgColor: AppColors.debitBg,
                    textColor: AppColors.debitText,
                    icon: Icons.arrow_upward,
                  ),
                  StatCard(
                    label: 'Net Balance',
                    value: transactionProvider.balance,
                    bgColor: Colors.blue.shade50,
                    textColor: AppColors.balanceText,
                    icon: Icons.wallet,
                  ),
                  StatCard(
                    label: 'Total Loads',
                    value: totalLoads.toDouble(),
                    bgColor: Colors.amber.shade50,
                    textColor: Colors.amber.shade900,
                    icon: Icons.local_shipping,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Party-wise balance section
              const Text(
                'Party-wise Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (partyBalances.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No data yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: partyBalances.length,
                  itemBuilder: (context, index) {
                    final item = partyBalances[index];
                    final party = item['party'] as Party;
                    final balance = item['balance'] as double;
                    final credit = item['credit'] as double;
                    final debit = item['debit'] as double;
                    final isPositive = balance >= 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Party avatar
                            Container(
                              width: 40,
                              height: 40,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'CR: ${Formatters.formatAmount(credit)} | DR: ${Formatters.formatAmount(debit)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Balance
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? AppColors.creditBg
                                    : AppColors.debitBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                Formatters.formatAmount(balance.abs()),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? AppColors.creditText
                                      : AppColors.debitText,
                                ),
                              ),
                            ),

                            // PDF button
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PDF generation coming soon'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              color: Colors.red,
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
