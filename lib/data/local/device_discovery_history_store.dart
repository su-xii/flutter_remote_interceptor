import 'package:shared_preferences/shared_preferences.dart';

const String _key = "DeviceDiscoveryHistoryStore";
class DeviceDiscoveryHistoryStore {
  Future<void> save(List<String> deviceIps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, deviceIps);
  }

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
