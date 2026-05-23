import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/router/router_util.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return RouterUtil.router;
});

final routerRefreshProvider = Provider<void Function()>((ref) {
  return () {};
});
