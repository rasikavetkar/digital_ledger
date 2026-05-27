import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ledger_screen.dart';
import 'parties_screen.dart';
import 'vehicles_screen.dart';
import 'summary_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../providers/party_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/transaction_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const LedgerScreen(),
      const PartiesScreen(),
      const VehiclesScreen(),
      const SummaryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digital Ledger'),
            Text(
              'Sand Transport Book',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Parties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionSheet,
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionSheet() {
    final partyProvider = context.read<PartyProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddTransactionSheet(
        parties: partyProvider.parties,
        vehicles: vehicleProvider.vehicles,
        onSave: (vehicleId, date, quantity, amount, type, remarks) {
          transactionProvider.addTransaction(
            vehicleId: vehicleId,
            date: date,
            quantity: quantity,
            amount: amount,
            type: type,
            remarks: remarks,
          );
        },
      ),
    );
  }
}
