import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/switch_device_dialog.dart';
import 'package:remote_interceptor/page/mock_response_page.dart';
import 'package:remote_interceptor/page/response_edit_page.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';
import 'package:remote_interceptor/state/home_state.dart';
import '../providers/viemodel_provider.dart';
import '../state/server_status_state.dart';
import '../widgets/link_switch.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);
    final serverStatus = ref.watch(serverStatusViewModelProvider);
    final notifier = ref.read(homeViewModelProvider.notifier);
    final homeState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: colors.bgPage,
      appBar: AppBar(
        title: LinkSwitch(
          isLink: homeState.interceptorMode == InterceptorMode.edit,
          onChanged: (_) => notifier.switchMode(),
        ),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => SwitchDeviceDialog(
                    onSwitchConfirmed: notifier.switchDevice),
              );
            },
            tooltip: '切换设备',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(
                  label: _getServerStatusText(serverStatus.serverStatus),
                  icon: _getServerStatusIcon(serverStatus.serverStatus),
                ),
                const SizedBox(width: 8),
                _buildStatusIndicator(
                  label:
                      _getClientStatusText(serverStatus.clientConnectionStatus),
                  icon:
                      _getClientStatusIcon(serverStatus.clientConnectionStatus),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: notifier.pageController,
              allowImplicitScrolling: true,
              children: [const ResponseEditPage(), const MockResponsePage()],
            ),
          )
        ],
      ),
    );
  }

  /// 构建通用的状态指示器 UI
  static Widget _buildStatusIndicator({
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _getServerStatusText(ServerStatus status) {
    switch (status) {
      case ServerStatus.starting:
        return '服务启动中';
      case ServerStatus.running:
        return '服务运行中';
      case ServerStatus.stopped:
        return '服务已停止';
    }
  }

  static IconData _getServerStatusIcon(ServerStatus status) {
    switch (status) {
      case ServerStatus.starting:
        return Icons.play_circle_outline;
      case ServerStatus.running:
        return Icons.dns;
      case ServerStatus.stopped:
        return Icons.stop_circle;
    }
  }

  static String _getClientStatusText(ClientConnectionStatus status) {
    switch (status) {
      case ClientConnectionStatus.disconnected:
        return '客户端未连接';
      case ClientConnectionStatus.connected:
        return '客户端已连接';
    }
  }

  static IconData _getClientStatusIcon(ClientConnectionStatus status) {
    switch (status) {
      case ClientConnectionStatus.disconnected:
        return Icons.devices_other;
      case ClientConnectionStatus.connected:
        return Icons.phone_iphone;
    }
  }
}
