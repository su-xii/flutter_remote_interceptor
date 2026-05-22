import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/page/device_discovery_page.dart';
import 'package:remote_interceptor/page/test_page.dart';
import 'package:remote_interceptor/application.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: Application(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DeviceDiscoveryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
