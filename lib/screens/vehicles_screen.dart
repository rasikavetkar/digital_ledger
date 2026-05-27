import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/party_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/add_vehicle_sheet.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  late TextEditingController _searchController;

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
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, _) {
        final partyProvider = context.read<PartyProvider>();
        final transactionProvider = context.read<TransactionProvider>();

        var filteredVehicles = vehicleProvider.vehicles;

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          filteredVehicles = vehicleProvider.searchVehicles(_searchController.text);
        }

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehicleProvider.vehicles.length} vehicles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVehicleSheet(context, partyProvider, vehicleProvider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search by vehicle number',
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

            // Vehicles list
            Expanded(
              child: filteredVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No vehicles found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddVehicleSheet(
                              context,
                              partyProvider,
                              vehicleProvider,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Vehicle'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        final party = partyProvider.getPartyById(vehicle.partyId);
                        final transactions = transactionProvider
                            .getTransactionsForVehicle(vehicle.id!);

                        return VehicleCard(
                          vehicle: vehicle,
                          ownerName: party?.name ?? 'Unknown',
                          tripCount: transactions.length,
                          totalLoads: transactions.fold(
                            0,
                            (sum, t) => sum + t.quantity,
                          ),
                          onTap: () {
                            // TODO: Navigate to vehicle detail screen
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

  void _showAddVehicleSheet(
    BuildContext context,
    PartyProvider partyProvider,
    VehicleProvider vehicleProvider,
  ) {
    if (partyProvider.parties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a party first')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddVehicleSheet(
        parties: partyProvider.parties,
        onSave: (number, partyId, type) {
          vehicleProvider.addVehicle(number, partyId, type);
        },
      ),
    );
  }
}
