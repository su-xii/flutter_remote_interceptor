import 'dart:convert';

import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _key = "MockRuleStore";

class MockRuleStore {
  Future<void> save(List<MockRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, rules.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<List<MockRule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
            .getStringList(_key)
            ?.map((e) => MockRule.fromJson(jsonDecode(e)))
            .toList() ??
        [];
  }
}
