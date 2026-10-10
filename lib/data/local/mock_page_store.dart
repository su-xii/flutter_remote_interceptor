import 'dart:convert';

import 'package:remote_interceptor/model/mock_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 页面级 Mock 配置的本地存储 key
const String _key = "MockPageStore";

/// 页面级 Mock 配置的持久化（与 MockRuleStore 保持同一套 SharedPreferences 方案）
class MockPageStore {
  /// 保存全部页面配置（整体覆盖）
  Future<void> save(List<MockPageConfig> pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(pages.map((e) => e.toJson()).toList()));
  }

  /// 读取全部页面配置；无数据或数据损坏时返回 `null`，由上层决定是否使用默认配置
  Future<List<MockPageConfig>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => MockPageConfig.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // 数据损坏（例如手工改坏）时按「无数据」处理，避免启动即崩溃
      return null;
    }
  }
}
