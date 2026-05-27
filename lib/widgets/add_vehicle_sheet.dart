import 'package:flutter/material.dart';
import '../models/party.dart';

class AddVehicleSheet extends StatefulWidget {
  final List<Party> parties;
  final Function(String number, int partyId, String type) onSave;

  const AddVehicleSheet({
    required this.parties,
    required this.onSave,
    super.key,
  });

  @override
  State<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<AddVehicleSheet> {
  final _numberController = TextEditingController();
  int? _selectedPartyId;
  String _selectedType = 'Truck';

  final vehicleTypes = ['Truck', 'Tractor', 'Tipper', 'Other'];

  @override
  void dispose() {
    _numberController.dispose();
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
                      'Add Vehicle',
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

                // Vehicle number field
                TextField(
                  controller: _numberController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number *',
                    hintText: 'e.g. GA08V6970',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.directions_car),
                  ),
                ),
                const SizedBox(height: 12),

                // Party dropdown
                DropdownButtonFormField<int>(
                  value: _selectedPartyId,
                  decoration: InputDecoration(
                    labelText: 'Party Owner *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: widget.parties.isEmpty
                      ? [const DropdownMenuItem(child: Text('No parties available'))]
                      : widget.parties.map((party) {
                          return DropdownMenuItem(
                            value: party.id,
                            child: Text(party.name),
                          );
                        }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPartyId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Vehicle type dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Type *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF185FA5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Vehicle',
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

  void _saveVehicle() {
    if (_numberController.text.isEmpty || _selectedPartyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    widget.onSave(
      _numberController.text.toUpperCase(),
      _selectedPartyId!,
      _selectedType,
    );
    Navigator.pop(context);
  }
}
