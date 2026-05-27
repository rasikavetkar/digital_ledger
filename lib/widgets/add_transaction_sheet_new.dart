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
    double quantity,
    double amount,
    String type,
    String? remarks,
  ) onSave;
  final Future<int> Function(String name, String? phone) onAddParty;
  final Future<int> Function(String number, int partyId, String type) onAddVehicle;

  const AddTransactionSheet({
    required this.parties,
    required this.vehicles,
    required this.onSave,
    required this.onAddParty,
    required this.onAddVehicle,
    super.key,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  DateTime _selectedDate = DateTime.now();
  Party? _selectedParty;
  Vehicle? _selectedVehicle;
  String _transactionType = 'credit';
  
  final _partyController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  List<Party> _filteredParties = [];
  List<Vehicle> _filteredVehicles = [];
  bool _showPartySuggestions = false;
  bool _showVehicleSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filteredParties = widget.parties;
    _filteredVehicles = widget.vehicles;
    
    _partyController.addListener(_onPartyChanged);
    _vehicleController.addListener(_onVehicleChanged);
  }

  @override
  void dispose() {
    _partyController.dispose();
    _vehicleController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onPartyChanged() {
    final query = _partyController.text.trim();
    setState(() {
      _showPartySuggestions = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredParties = widget.parties;
        _selectedParty = null;
        _selectedVehicle = null;
        _vehicleController.clear();
      } else {
        _filteredParties = widget.parties
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        
        // Exact case-insensitive match check
        try {
          _selectedParty = widget.parties.firstWhere(
            (p) => p.name.trim().toLowerCase() == query.toLowerCase(),
          );
        } catch (_) {
          _selectedParty = null;
        }
      }
    });
  }

  void _onVehicleChanged() {
    final query = _vehicleController.text.trim();
    setState(() {
      _showVehicleSuggestions = query.isNotEmpty;
      if (query.isEmpty) {
        _selectedVehicle = null;
        _filteredVehicles = _selectedParty != null
            ? widget.vehicles.where((v) => v.partyId == _selectedParty!.id).toList()
            : widget.vehicles;
      } else {
        final candidates = _selectedParty != null
            ? widget.vehicles.where((v) => v.partyId == _selectedParty!.id)
            : widget.vehicles;
        _filteredVehicles = candidates
            .where((v) => v.number.toLowerCase().contains(query.toLowerCase()))
            .toList();
        
        // Exact case-insensitive match check
        try {
          final matchingVehicle = widget.vehicles.firstWhere(
            (v) => v.number.trim().toUpperCase() == query.toUpperCase(),
          );
          _selectedVehicle = matchingVehicle;
          
          // Auto-fill owner party if not set or different
          final matchingParty = widget.parties.firstWhere(
            (p) => p.id == matchingVehicle.partyId,
          );
          _selectedParty = matchingParty;
          _partyController.text = matchingParty.name;
          _showPartySuggestions = false;
        } catch (_) {
          _selectedVehicle = null;
        }
      }
    });
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
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  16,
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

                // Party autocomplete
                TextField(
                  controller: _partyController,
                  decoration: InputDecoration(
                    labelText: 'Party (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _selectedParty != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _partyController.clear();
                              _selectedParty = null;
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                if (_showPartySuggestions && _filteredParties.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredParties.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredParties.length) {
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: Text('Create new: "${_partyController.text}"'),
                            onTap: () => _createNewParty(_partyController.text),
                          );
                        }
                        final party = _filteredParties[index];
                        return ListTile(
                          title: Text(party.name),
                          subtitle: party.phone != null ? Text(party.phone!) : null,
                          onTap: () {
                            _selectedParty = party;
                            _partyController.text = party.name;
                            _showPartySuggestions = false;
                            _selectedVehicle = null;
                            _vehicleController.clear();
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),

                // Vehicle autocomplete
                TextField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.directions_car),
                    suffixIcon: _selectedVehicle != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _vehicleController.clear();
                              _selectedVehicle = null;
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                if (_showVehicleSuggestions && _filteredVehicles.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredVehicles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _filteredVehicles.length) {
                          return ListTile(
                            leading: const Icon(Icons.add),
                            title: Text('Create new: "${_vehicleController.text}"'),
                            onTap: () {
                              if (_selectedParty == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Select a party first')),
                                );
                                return;
                              }
                              _createNewVehicle(_vehicleController.text);
                            },
                          );
                        }
                        final vehicle = _filteredVehicles[index];
                        return ListTile(
                          title: Text(vehicle.number),
                          subtitle: Text(vehicle.type),
                          onTap: () {
                            _selectedVehicle = vehicle;
                            _vehicleController.text = vehicle.number;
                            _showVehicleSuggestions = false;
                            setState(() {});
                          },
                        );
                      },
                    ),
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

  void _createNewParty(String name) async {
    final id = await widget.onAddParty(name, null);
    _selectedParty = Party(id: id, name: name, createdAt: DateTime.now());
    _partyController.text = name;
    _showPartySuggestions = false;
    setState(() {});
  }

  void _createNewVehicle(String number) async {
    if (_selectedParty == null) return;
    final id = await widget.onAddVehicle(number, _selectedParty!.id!, 'Truck');
    _selectedVehicle = Vehicle(
      id: id,
      number: number,
      partyId: _selectedParty!.id!,
      type: 'Truck',
      createdAt: DateTime.now(),
    );
    _vehicleController.text = number;
    _showVehicleSuggestions = false;
    setState(() {});
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

  void _saveTransaction() async {
    final vehicleText = _vehicleController.text.trim();
    if (vehicleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle number is required')),
      );
      return;
    }
    if (_quantityController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // 1. Resolve party ID
      int? partyId;
      final partyText = _partyController.text.trim();
      
      if (partyText.isNotEmpty) {
        // Look for exact match (case-insensitive) in existing parties
        Party? existingParty;
        for (var p in widget.parties) {
          if (p.name.trim().toLowerCase() == partyText.toLowerCase()) {
            existingParty = p;
            break;
          }
        }
        if (existingParty != null) {
          partyId = existingParty.id;
        } else {
          // Create new party
          partyId = await widget.onAddParty(partyText, null);
        }
      } else {
        // If party is empty, check if vehicle exists
        Vehicle? existingVehicle;
        for (var v in widget.vehicles) {
          if (v.number.trim().toUpperCase() == vehicleText.toUpperCase()) {
            existingVehicle = v;
            break;
          }
        }
        if (existingVehicle != null) {
          partyId = existingVehicle.partyId;
        } else {
          // It's a new vehicle with no party name typed.
          // Auto-create a party using the vehicle number to satisfy db constraints.
          partyId = await widget.onAddParty(vehicleText.toUpperCase(), null);
        }
      }

      // 2. Resolve vehicle ID
      int? vehicleId;
      Vehicle? existingVehicle;
      for (var v in widget.vehicles) {
        if (v.number.trim().toUpperCase() == vehicleText.toUpperCase()) {
          existingVehicle = v;
          break;
        }
      }

      if (existingVehicle != null) {
        vehicleId = existingVehicle.id;
      } else {
        // Create new vehicle
        vehicleId = await widget.onAddVehicle(vehicleText.toUpperCase(), partyId!, 'Truck');
      }

      // 3. Save the transaction
      if (!mounted) return;
      widget.onSave(
        vehicleId!,
        _selectedDate,
        double.parse(_quantityController.text),
        double.parse(_amountController.text),
        _transactionType,
        _remarksController.text.isEmpty ? null : _remarksController.text,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
