import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_rate.dart';

const _kStorageKey = '@lukas_multi_rates';

class CustomRatesStore extends ChangeNotifier {
  List<CustomRate> _rates = [];

  List<CustomRate> get rates => List.unmodifiable(_rates);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kStorageKey);
      if (saved == null) return;
      final list = (jsonDecode(saved) as List<dynamic>)
          .map((e) => CustomRate.fromJson(e as Map<String, dynamic>))
          .toList();
      _rates = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando tasas custom: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kStorageKey,
        jsonEncode(_rates.map((r) => r.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error guardando tasas custom: $e');
    }
  }

  Future<String> upsert({
    CustomRate? editing,
    required String name,
    required String value,
    required String icon,
  }) async {
    String newId;
    if (editing != null) {
      _rates = _rates
          .map((r) => r.id == editing.id
              ? r.copyWith(name: name, value: value, icon: icon)
              : r)
          .toList();
      newId = editing.id;
    } else {
      final newRate = CustomRate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        value: value,
        icon: icon,
      );
      _rates = [..._rates, newRate];
      newId = newRate.id;
    }
    notifyListeners();
    await _persist();
    return newId;
  }

  Future<void> delete(String id) async {
    _rates = _rates.where((r) => r.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> reorder(List<CustomRate> newOrder) async {
    _rates = List.of(newOrder);
    notifyListeners();
    await _persist();
  }
}
