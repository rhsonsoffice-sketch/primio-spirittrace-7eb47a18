import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/investigation.dart';

class InvestigationRepository {
  static const _storageKey = 'spirit_trace_investigations';

  Future<List<Investigation>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Investigation.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  Future<Investigation?> getById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((inv) => inv.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Investigation investigation) async {
    final all = await getAll();
    final idx = all.indexWhere((inv) => inv.id == investigation.id);
    if (idx >= 0) {
      all[idx] = investigation;
    } else {
      all.add(investigation);
    }
    await _persist(all);
  }

  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((inv) => inv.id == id);
    await _persist(all);
  }

  Future<bool> getFlag(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('spirit_trace_flag_$key') ?? false;
  }

  Future<void> setFlag(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('spirit_trace_flag_$key', value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('spirit_trace_pref_$key');
  }

  Future<void> setString(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('spirit_trace_pref_$key');
    } else {
      await prefs.setString('spirit_trace_pref_$key', value);
    }
  }

  Future<void> _persist(List<Investigation> investigations) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(investigations.map((i) => i.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
