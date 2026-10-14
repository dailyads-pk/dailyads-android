import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Saved advertisements and recent searches, kept on this device only.
class SavedStore extends ChangeNotifier {
  SavedStore._();
  static final instance = SavedStore._();

  static const _savedKey = 'saved_ads_v1';
  static const _recentKey = 'recent_searches_v1';

  late SharedPreferences _prefs;
  final List<AdSummary> _saved = [];
  final List<String> _recent = [];

  List<AdSummary> get saved => List.unmodifiable(_saved);
  List<String> get recentSearches => List.unmodifiable(_recent);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_savedKey);
    if (raw != null) {
      try {
        _saved.addAll((jsonDecode(raw) as List).map((e) => AdSummary.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        await _prefs.remove(_savedKey);
      }
    }
    _recent.addAll(_prefs.getStringList(_recentKey) ?? const []);
  }

  bool isSaved(int id) => _saved.any((a) => a.id == id);

  Future<void> toggle(AdSummary ad) async {
    if (isSaved(ad.id)) {
      _saved.removeWhere((a) => a.id == ad.id);
    } else {
      _saved.insert(0, ad);
    }
    notifyListeners();
    await _prefs.setString(_savedKey, jsonEncode(_saved.map((a) => a.toJson()).toList()));
  }

  Future<void> addRecentSearch(String q) async {
    final v = q.trim();
    if (v.isEmpty) return;
    _recent.removeWhere((s) => s.toLowerCase() == v.toLowerCase());
    _recent.insert(0, v);
    if (_recent.length > 8) _recent.removeRange(8, _recent.length);
    notifyListeners();
    await _prefs.setStringList(_recentKey, _recent);
  }

  Future<void> clearRecentSearches() async {
    _recent.clear();
    notifyListeners();
    await _prefs.remove(_recentKey);
  }
}
