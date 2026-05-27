import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/vehicle.dart';

class VehicleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Vehicle> _vehicles = [];

  List<Vehicle> get vehicles => _vehicles;

  VehicleProvider() {
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    _vehicles = await _db.getAllVehicles();
    notifyListeners();
  }

  Future<int> addVehicle(String number, int partyId, String type) async {
    final vehicle = Vehicle(
      number: number.toUpperCase(),
      partyId: partyId,
      type: type,
    );
    final id = await _db.insertVehicle(vehicle);
    await loadVehicles();
    return id;
  }

  Future<void> deleteVehicle(int id) async {
    await _db.deleteVehicle(id);
    await loadVehicles();
  }

  Future<void> updateVehicle(int id, String number, String type) async {
    final vehicle = Vehicle(
      id: id,
      number: number.toUpperCase(),
      partyId: _vehicles.firstWhere((v) => v.id == id).partyId,
      type: type,
    );
    await _db.updateVehicle(vehicle);
    await loadVehicles();
  }

  List<Vehicle> getVehiclesForParty(int partyId) {
    return _vehicles.where((v) => v.partyId == partyId).toList();
  }

  List<Vehicle> searchVehicles(String query) {
    if (query.isEmpty) return _vehicles;
    final lowerQuery = query.toLowerCase();
    return _vehicles
        .where((v) => v.number.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Vehicle? getVehicleById(int? id) {
    if (id == null) return null;
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> getVehicleCountForParty(int partyId) async {
    return getVehiclesForParty(partyId).length;
  }

  Future<void> clearAllData() async {
    await loadVehicles();
  }
}
