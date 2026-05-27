import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/vehicle.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<Party> parties;
  final List<Vehicle> vehicles;
  final Function(
    int vehicleId,
    DateTime date,
    int quantity,
    double amount,
    String type,
    String? remarks,
  ) onSave;

  const AddTransactionSheet({
    required this.parties,
    required this.vehicles,
    required this.onSave,
    super.key,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedPartyId;
  int? _selectedVehicleId;
  String _transactionType = 'credit';
  
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  late List<Vehicle> _filteredVehicles;

  @override
  void initState() {
    super.initState();
    _filteredVehicles = widget.vehicles;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                  ),
                  onTap: _selectDate,
                  trailing: const Icon(Icons.chevron_right),
                ),
                const SizedBox(height: 12),

                // Party dropdown
                DropdownButtonFormField<int>(
                  value: _selectedPartyId,
                  decoration: InputDecoration(
                    labelText: 'Party (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Parties'),
                    ),
                    ...widget.parties.map((party) {
                      return DropdownMenuItem(
                        value: party.id,
                        child: Text(party.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPartyId = value;
                      _selectedVehicleId = null;
                      _updateFilteredVehicles();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Vehicle dropdown
                DropdownButtonFormField<int>(
                  value: _selectedVehicleId,
                  decoration: InputDecoration(
                    labelText: 'Vehicle *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.directions_car),
                  ),
                  items: _filteredVehicles.isEmpty
                      ? [const DropdownMenuItem(child: Text('No vehicles available'))]
                      : _filteredVehicles.map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(vehicle.number),
                          );
                        }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVehicleId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Credit / Debit toggle
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const <ButtonSegment<String>>[
                          ButtonSegment<String>(
                            value: 'credit',
                            label: Text('Credit'),
                            icon: Icon(Icons.arrow_downward),
                          ),
                          ButtonSegment<String>(
                            value: 'debit',
                            label: Text('Debit'),
                            icon: Icon(Icons.arrow_upward),
                          ),
                        ],
                        selected: <String>{_transactionType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _transactionType = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity field
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity (loads) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.production_quantity_limits),
                  ),
                ),
                const SizedBox(height: 12),

                // Amount field
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 12),

                // Remarks field
                TextField(
                  controller: _remarksController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Remarks (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateFilteredVehicles() {
    if (_selectedPartyId == null) {
      _filteredVehicles = widget.vehicles;
    } else {
      _filteredVehicles = widget.vehicles
          .where((v) => v.partyId == _selectedPartyId)
          .toList();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_selectedVehicleId == null ||
        _quantityController.text.isEmpty ||
        _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      widget.onSave(
        _selectedVehicleId!,
        _selectedDate,
        int.parse(_quantityController.text),
        double.parse(_amountController.text),
        _transactionType,
        _remarksController.text.isEmpty ? null : _remarksController.text,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
