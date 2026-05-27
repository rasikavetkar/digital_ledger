import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../utils/theme.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String ownerName;
  final int tripCount;
  final int totalLoads;
  final VoidCallback onTap;

  const VehicleCard({
    required this.vehicle,
    required this.ownerName,
    required this.tripCount,
    required this.totalLoads,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getVehicleIcon();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.number,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ownerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${vehicle.type}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$tripCount trips',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$totalLoads loads',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleIcon() {
    switch (vehicle.type.toLowerCase()) {
      case 'truck':
        return Icons.local_shipping;
      case 'tractor':
        return Icons.agriculture;
      case 'tipper':
        return Icons.construction;
      default:
        return Icons.directions_car;
    }
  }
}
