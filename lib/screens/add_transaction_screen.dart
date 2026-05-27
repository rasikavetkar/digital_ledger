import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/party_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? preselectedPartyId;
  final String? preselectedType; // 'Credit' (Jama) or 'Debit' (Udhaar)

  const AddTransactionScreen({
    super.key,
    this.preselectedPartyId,
    this.preselectedType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String? _selectedPartyId;
  String? _selectedVehicleId;
  late String _transactionType; // 'Credit' or 'Debit'
  late DateTime _selectedDate;

  final _dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');



  @override
  void initState() {
    super.initState();
    _selectedPartyId = widget.preselectedPartyId;
    _transactionType = widget.preselectedType ?? 'Credit'; // Default to Jama / Credit
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF10B981),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final partyProvider = context.read<PartyProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    final parties = partyProvider.parties;
    final vehicles = vehicleProvider.vehicles;

    final isCredit = _transactionType == 'Credit';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preselectedPartyId != null ? 'Add Entry' : 'Record Transaction'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. CREDIT/DEBIT TOGGLE BAR ---
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _transactionType = 'Credit';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCredit
                              ? const Color(0xFF10B981)
                              : const Color(0xFF1E293B),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Text(
                          'JAMA (Got Money)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _transactionType = 'Debit';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !isCredit
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1E293B),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Text(
                          'UDHAAR (Gave Money)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !isCredit ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- 2. CONTACT LEDGER SELECTOR ---
              if (widget.preselectedPartyId != null) ...[
                // Lock and display name
                Builder(
                  builder: (context) {
                    final party = parties.firstWhere((p) => p.id == _selectedPartyId);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white54),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recording for Ledger', style: TextStyle(fontSize: 11, color: Colors.white38)),
                              Text(
                                party.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                // Searchable party dropdown
                DropdownButtonFormField<int?>(
                  value: _selectedPartyId?.isEmpty ?? true ? null : int.tryParse(_selectedPartyId ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Select Business Contact *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  dropdownColor: const Color(0xFF1E293B),
                  items: parties.map((p) {
                    return DropdownMenuItem<int?>(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPartyId = val?.toString();
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),

              // --- 3. RUPEES AMOUNT FIELD ---
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (in Rupees) *',
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12.0, right: 6.0),
                    child: Text('₹', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 16),

              // --- 4. DETAILS / DESCRIPTION BOX WITH AUTOMATED PILLS ---
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Details (e.g. Trips, Goods) *',
                  hintText: 'e.g. 3 trip / diesel charges / cash advance',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 8),
              
              const SizedBox(height: 20),

              // --- 5. OPTIONAL VEHICLE SELECTOR ---
              DropdownButtonFormField<String?>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Assign to Vehicle (Optional)',
                  prefixIcon: Icon(Icons.local_shipping),
                  hintText: 'Select Truck Plate',
                ),
                dropdownColor: const Color(0xFF1E293B),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('No Vehicle (Direct Ledger)')),
                  ...vehicles.map((v) {
                    return DropdownMenuItem<String?>(
                      value: v.id?.toString(),
                      child: Text('${v.number} (${v.type})'),
                    );
                  }),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedVehicleId = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // --- 6. DATE SELECTION CONTROLLER ---
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transaction Date & Time', style: TextStyle(fontSize: 10, color: Colors.white38)),
                              Text(
                                _dateFormat.format(_selectedDate),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.edit, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 7. SAVE TRANSACTION BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final amountText = _amountController.text.trim();
                    final details = _detailsController.text.trim();

                    if (_selectedPartyId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a business contact')),
                      );
                      return;
                    }

                    if (amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Amount must be a positive number')),
                      );
                      return;
                    }

                    if (details.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in transaction details')),
                      );
                      return;
                    }

                    // Save the entry!
                    if (_selectedPartyId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a party')),
                      );
                      return;
                    }

                    transactionProvider.addTransaction(
                      vehicleId: _selectedVehicleId != null ? int.tryParse(_selectedVehicleId!) : null,
                      date: _selectedDate,
                      quantity: 1, // Default to 1 load
                      amount: amount,
                      type: _transactionType.toLowerCase(),
                      remarks: details,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Entry of ₹$amountText recorded successfully'),
                        backgroundColor: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Ledger Entry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
