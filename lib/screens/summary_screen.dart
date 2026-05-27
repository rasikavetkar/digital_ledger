import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/party_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/party.dart';
import '../widgets/stat_card.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../services/pdf_service.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This action is irreversible. All parties, vehicles, and transactions will be permanently deleted from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final transactionProvider = context.read<TransactionProvider>();
              final partyProvider = context.read<PartyProvider>();
              final vehicleProvider = context.read<VehicleProvider>();
              Navigator.pop(dialogContext);
              
              // Clear providers
              await transactionProvider.clearAllData();
              await partyProvider.clearAllData();
              await vehicleProvider.clearAllData();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been successfully cleared')),
                );
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final partyProvider = context.read<PartyProvider>();

        // Calculate total loads
        final totalLoads = transactionProvider.transactions
            .fold(0.0, (sum, t) => sum + t.quantity);

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

        // Group transactions by month
        final monthlyData = <DateTime, Map<String, double>>{};
        for (var t in transactionProvider.transactions) {
          final monthDate = DateTime(t.date.year, t.date.month);
          if (!monthlyData.containsKey(monthDate)) {
            monthlyData[monthDate] = {'credit': 0.0, 'debit': 0.0};
          }
          monthlyData[monthDate]![t.type] = (monthlyData[monthDate]![t.type] ?? 0.0) + t.amount;
        }

        // Sort months chronologically
        final sortedMonths = monthlyData.keys.toList()..sort((a, b) => a.compareTo(b));

        // Take last 6 months
        final displayMonths = sortedMonths.length > 6
            ? sortedMonths.sublist(sortedMonths.length - 6)
            : sortedMonths;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title + Clear All button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Clear All Data', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showClearConfirmationDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

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
                    value: totalLoads,
                    bgColor: Colors.amber.shade50,
                    textColor: Colors.amber.shade900,
                    icon: Icons.local_shipping,
                  ),
                ],
              ),

              // Monthly bar chart
              _buildMonthlyChart(context, displayMonths, monthlyData),

              const SizedBox(height: 16),

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
                              onPressed: () async {
                                final vehicles = context.read<VehicleProvider>().getVehiclesForParty(party.id!);
                                final transactions = transactionProvider.getTransactionsForParty(party.id!);
                                final messenger = ScaffoldMessenger.of(context);
                                
                                try {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Generating invoice…'),
                                        ],
                                      ),
                                    ),
                                  );
                                  await PdfService.generatePartyInvoice(party, vehicles, transactions);
                                  messenger.hideCurrentSnackBar();
                                } catch (e) {
                                  messenger.hideCurrentSnackBar();
                                  if (context.mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Failed to generate invoice: $e')),
                                    );
                                  }
                                }
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

  Widget _buildMonthlyChart(
    BuildContext context,
    List<DateTime> months,
    Map<DateTime, Map<String, double>> data,
  ) {
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Credit vs Debit performance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(months, data),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey.shade800,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final type = rodIndex == 0 ? 'Credit' : 'Debit';
                        return BarTooltipItem(
                          '$type\n${Formatters.formatAmount(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final date = months[index];
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(months.length, (index) {
                    final month = months[index];
                    final credit = data[month]?['credit'] ?? 0.0;
                    final debit = data[month]?['debit'] ?? 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: credit,
                          color: AppColors.creditText,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: debit,
                          color: AppColors.debitText,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
              ),
            ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.creditText, label: 'Credit'),
                const SizedBox(width: 24),
                _LegendItem(color: AppColors.debitText, label: 'Debit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<DateTime> months, Map<DateTime, Map<String, double>> data) {
    double max = 0.0;
    for (var m in months) {
      final credit = data[m]?['credit'] ?? 0.0;
      final debit = data[m]?['debit'] ?? 0.0;
      if (credit > max) max = credit;
      if (debit > max) max = debit;
    }
    return max == 0 ? 1000.0 : max * 1.15;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
