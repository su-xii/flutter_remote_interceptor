import 'dart:convert';

import 'package:remote_interceptor/model/device_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _key = "DeviceDiscoveryHistoryStore";

class DeviceDiscoveryHistoryStore {
  Future<void> save(List<DeviceModel> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, devices.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<List<DeviceModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
            .getStringList(_key)
            ?.map((e) => DeviceModel.fromJson(jsonDecode(e)))
            .toList() ??
        [];
  }
}
