import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/application.dart';
import 'package:remote_interceptor/router/router_util.dart';
import 'package:remote_interceptor/providers/providers.dart';

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
    return MaterialApp.router(
      title: 'Remote Interceptor',
      debugShowCheckedModeBanner: false,
      routerConfig: RouterUtil.router,
    );
  }
}
