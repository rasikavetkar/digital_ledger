import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/vehicle.dart';
import '../models/party.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _fileName = 'ledger_data.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> saveData({
    required List<Vehicle> vehicles,
    required List<Party> parties,
    required List<Transaction> transactions,
  }) async {
    try {
      final file = await _getLocalFile();
      final data = {
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'parties': parties.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      // Quietly log error or handle custom alerts in debug mode
      print('Error saving ledger data: $e');
    }
  }

  Future<Map<String, dynamic>> loadData() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return {
          'vehicles': <Vehicle>[],
          'parties': <Party>[],
          'transactions': <Transaction>[],
        };
      }

      final contents = await file.readAsString();
      final decoded = jsonDecode(contents) as Map<String, dynamic>;

      final rawVehicles = decoded['vehicles'] as List<dynamic>? ?? [];
      final rawParties = decoded['parties'] as List<dynamic>? ?? [];
      final rawTransactions = decoded['transactions'] as List<dynamic>? ?? [];

      final vehicles = rawVehicles.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
      final parties = rawParties.map((json) => Party.fromJson(json as Map<String, dynamic>)).toList();
      final transactions = rawTransactions.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();

      return {
        'vehicles': vehicles,
        'parties': parties,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error loading ledger data: $e');
      return {
        'vehicles': <Vehicle>[],
        'parties': <Party>[],
        'transactions': <Transaction>[],
      };
    }
  }
}
