import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/device_discovery_history_store.dart';

final deviceDiscoveryHistory = Provider((ref) => DeviceDiscoveryHistoryStore());
