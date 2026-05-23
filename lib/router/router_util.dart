import 'package:go_router/go_router.dart';
import '../page/device_discovery_page.dart';
import '../page/home_page.dart';

class RouterUtil {
  static const String deviceDiscovery = '/';
  static const String home = '/home';

  static final GoRouter router = GoRouter(
    initialLocation: deviceDiscovery,
    routes: [
      GoRoute(
        path: deviceDiscovery,
        name: 'deviceDiscovery',
        builder: (context, state) => const DeviceDiscoveryPage(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );

  static void goToHome() {
    router.go(home);
  }

  static void goToDeviceDiscovery() {
    router.go(deviceDiscovery);
  }
}
