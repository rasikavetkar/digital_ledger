import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/party.dart';

class PartyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Party> _parties = [];

  List<Party> get parties => _parties;

  PartyProvider() {
    loadParties();
  }

  Future<void> loadParties() async {
    _parties = await _db.getParties();
    notifyListeners();
  }

  Future<int> addParty(String name, String? phone) async {
    final party = Party(
      name: name,
      phone: phone,
    );
    final id = await _db.insertParty(party);
    await loadParties();
    return id;
  }

  Future<void> deleteParty(int id) async {
    await _db.deleteParty(id);
    await loadParties();
  }

  Future<void> updateParty(int id, String name, String? phone) async {
    final party = Party(
      id: id,
      name: name,
      phone: phone,
    );
    await _db.updateParty(party);
    await loadParties();
  }

  Party? getPartyById(int id) {
    try {
      return _parties.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<int> getPartyCount() async {
    return _parties.length;
  }

  Future<void> clearAllData() async {
    await loadParties();
  }
}
