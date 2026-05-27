import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/party_provider.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          final partyProvider = context.read<PartyProvider>();
          final vehicles = vehicleProvider.vehicles;

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 72, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'No vehicles registered yet.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVehicleDialog(context, vehicleProvider, partyProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search vehicles...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final vehicle = vehicles[i];
                    final party = partyProvider.getPartyById(vehicle.partyId);

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text(vehicle.number, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${vehicle.type}'),
                            if (party != null) Text('Owner: ${party.name}'),
                          ],
                        ),
                        onTap: () => Navigator.pop(context, vehicle),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context, context.read<VehicleProvider>(), context.read<PartyProvider>()),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, VehicleProvider vehicleProvider, PartyProvider partyProvider) {
    String? selectedPartyId;
    String vehicleNumber = '';
    String vehicleType = 'Truck';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (val) => vehicleNumber = val,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number *',
                    hintText: 'e.g., MH02AB1234',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPartyId,
                  hint: const Text('Select Owner *'),
                  items: partyProvider.parties.map((p) {
                    return DropdownMenuItem(
                      value: p.id?.toString(),
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPartyId = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  items: const [
                    DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                    DropdownMenuItem(value: 'Tractor', child: Text('Tractor')),
                    DropdownMenuItem(value: 'Tipper', child: Text('Tipper')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => vehicleType = val ?? 'Truck'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (vehicleNumber.isEmpty || selectedPartyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                vehicleProvider.addVehicle(
                  vehicleNumber,
                  int.parse(selectedPartyId!),
                  vehicleType,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vehicle $vehicleNumber added')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
