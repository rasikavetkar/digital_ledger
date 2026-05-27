import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';
import '../models/vehicle.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Transaction> _transactions = [];
  List<Vehicle> _vehicles = [];

  List<Transaction> get transactions => _transactions;

  TransactionProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final txns = await _db.getTransactions();
    _transactions = txns.cast<Transaction>();
    _vehicles = await _db.getAllVehicles();
    notifyListeners();
  }

  Future<int> addTransaction({
    int? vehicleId,
    required DateTime date,
    required double quantity,
    required double amount,
    required String type,
    String? remarks,
  }) async {
    final transaction = Transaction(
      vehicleId: vehicleId,
      date: date,
      quantity: quantity,
      amount: amount,
      type: type,
      remarks: remarks,
    );
    final id = await _db.insertTransaction(transaction);
    await loadTransactions();
    return id;
  }

  Future<void> deleteTransaction(int id) async {
    final transaction = getTransactionById(id);
    if (transaction != null && transaction.vehicleId != null) {
      final vehicleId = transaction.vehicleId!;
      await _db.deleteTransaction(id);
      
      // Check if this vehicle has any other transactions
      final remainingTxns = await _db.getTransactionsByVehicle(vehicleId);
      if (remainingTxns.isEmpty) {
        final vehicle = await _db.getVehicleById(vehicleId);
        await _db.deleteVehicle(vehicleId);
        
        if (vehicle != null) {
          final partyId = vehicle.partyId;
          final remainingVehicles = await _db.getVehiclesByParty(partyId);
          if (remainingVehicles.isEmpty) {
            await _db.deleteParty(partyId);
          }
        }
      }
    } else {
      await _db.deleteTransaction(id);
    }
    await loadTransactions();
  }

  Future<void> updateTransaction({
    required int id,
    required int vehicleId,
    required DateTime date,
    required double quantity,
    required double amount,
    required String type,
    String? remarks,
  }) async {
    final transaction = Transaction(
      id: id,
      vehicleId: vehicleId,
      date: date,
      quantity: quantity,
      amount: amount,
      type: type,
      remarks: remarks,
    );
    await _db.updateTransaction(transaction);
    await loadTransactions();
  }

  List<Transaction> filterByType(String type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  List<Transaction> filterByParty(int partyId) {
    final vehicleIds = _vehicles
        .where((v) => v.partyId == partyId)
        .map((v) => v.id)
        .toList();
    return _transactions
        .where((t) => vehicleIds.contains(t.vehicleId))
        .toList();
  }

  List<Transaction> filterByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions
        .where((t) =>
            t.date.isAfter(startDate) && t.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  List<Transaction> searchByVehicleOrOwner(String query, List<Vehicle> vehicles) {
    if (query.isEmpty) return _transactions;
    final lowerQuery = query.toLowerCase();
    
    final matchingVehicles = vehicles
        .where((v) => v.number.toLowerCase().contains(lowerQuery))
        .map((v) => v.id)
        .toList();

    return _transactions
        .where((t) => matchingVehicles.contains(t.vehicleId))
        .toList();
  }

  // Computed getters
  double get totalCredit {
    return _transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalDebit {
    return _transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance {
    return totalCredit - totalDebit;
  }

  Transaction? getTransactionById(int id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<double> getCreditTotalByParty(int partyId) async {
    return _db.getCreditTotalByParty(partyId);
  }

  Future<double> getDebitTotalByParty(int partyId) async {
    return _db.getDebitTotalByParty(partyId);
  }

  Future<double> getTotalLoads() async {
    return _db.getTotalLoads();
  }

  List<Transaction> getTransactionsForParty(int partyId) {
    final vehicleIds = _vehicles
        .where((v) => v.partyId == partyId)
        .map((v) => v.id!)
        .toList();
    return _transactions
        .where((t) => vehicleIds.contains(t.vehicleId))
        .toList();
  }

  List<Transaction> getTransactionsForVehicle(int vehicleId) {
    return _transactions.where((t) => t.vehicleId == vehicleId).toList();
  }

  Future<void> clearAllData() async {
    await _db.clearAllData();
    await loadTransactions();
  }
}
