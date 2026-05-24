import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import '../providers/providers.dart';
import '../state/server_status_state.dart';
import '../widgets/request_list_page.dart';
import '../widgets/server_status_indicator.dart';
import '../state/home_state.dart';
import '../viewmodel/home_viewmodel.dart';

const Color kPrimaryColor = Color(0xFF165DFF);
const Color kSuccessColor = Color(0xFF00B42A);
const Color kWarningColor = Color(0xFFFF7D00);
const Color kErrorColor = Color(0xFFF53F3F);
const Color kTextPrimary = Color(0xFF1D2129);
const Color kTextSecondary = Color(0xFF86909C);
const Color kBgCard = Color(0xFFFFFFFF);
const Color kBgPage = Color(0xFFF2F3F5);
const Color kBorderLight = Color(0xFFE5E6EB);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CodeLineEditingController _editorController = CodeLineEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

  }

  @override
  void dispose() {
    _tabController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  late final serverStatus = ref.watch(serverStatusViewModelProvider);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final notifier = ref.read(homeViewModelProvider.notifier);

    if (state.currentJsonText.isNotEmpty && _editorController.text != state.currentJsonText) {
      _editorController.text = state.currentJsonText;
    }

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: const Text(
          'JSON 拦截编辑器',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => _buildSwitchDeviceDialog(context, notifier),
              );
            },
            tooltip: '切换设备',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                () {
                  final status = ref.watch(serverStatusViewModelProvider);
                  return _buildStatusIndicator(
                    _getServerStatusText(status.serverStatus),
                    _getServerStatusIcon(status.serverStatus),
                    _getServerStatusColor(status.serverStatus),
                  );
                }(),
                const SizedBox(width: 8),
                () {
                  final status = ref.watch(serverStatusViewModelProvider).clientConnectionStatus;
                  return _buildStatusIndicator(
                    _getClientStatusText(status),
                    _getClientStatusIcon(status),
                    _getClientStatusColor(status),
                  );
                }(),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 全局控制栏 - 始终可见
          _buildGlobalControlBar(state, notifier),
          // Tab导航
          _buildTabBar(),
          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditorTab(state, notifier),
                const RequestListPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalControlBar(HomeState state, HomeViewModel notifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 拦截开关
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: state.isIntercepting
                    ? kWarningColor.withOpacity(0.1)
                    : kTextSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.isIntercepting ? kWarningColor : kTextSecondary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isIntercepting ? Icons.shield : Icons.shield_outlined,
                    color: state.isIntercepting ? kWarningColor : kTextSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    state.isIntercepting ? '拦截开启' : '拦截关闭',
                    style: TextStyle(
                      color: state.isIntercepting ? kWarningColor : kTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: state.isIntercepting,
                      onChanged: (value) {
                        notifier.toggleIntercepting(value);
                      },
                      activeColor: kWarningColor,
                      activeTrackColor: kWarningColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 队列信息
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.queue,
                  size: 22,
                  color: kPrimaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  '队列: ${state.requestQueue.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: kBgCard,
      child: TabBar(
        controller: _tabController,
        labelColor: kPrimaryColor,
        unselectedLabelColor: kTextSecondary,
        indicatorColor: kPrimaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 6),
                Text('当前请求', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.list, size: 20),
                SizedBox(width: 6),
                Text('请求记录', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, IconData icon, Color color) {
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

  Widget _buildSwitchDeviceDialog(BuildContext context, HomeViewModel notifier) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWarningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 40,
                color: kWarningColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '切换设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '确定要断开当前连接并选择其他设备吗？',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      notifier.navigateToDeviceDiscovery();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '确定',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getServerStatusText(ServerStatus status) {
    switch (status) {
      case ServerStatus.starting:
        return '服务启动中';
      case ServerStatus.running:
        return '服务运行中';
      case ServerStatus.stopped:
        return '服务已停止';
    }
  }

  IconData _getServerStatusIcon(ServerStatus status) {
    switch (status) {
      case ServerStatus.starting:
        return Icons.play_circle_outline;
      case ServerStatus.running:
        return Icons.dns;
      case ServerStatus.stopped:
        return Icons.stop_circle;
    }
  }

  Color _getServerStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.starting:
        return kWarningColor;
      case ServerStatus.running:
        return kSuccessColor;
      case ServerStatus.stopped:
        return kTextSecondary;
    }
  }

  String _getClientStatusText(ClientConnectionStatus status) {
    switch (status) {
      case ClientConnectionStatus.disconnected:
        return '客户端未连接';
      case ClientConnectionStatus.connected:
        return '客户端已连接';
    }
  }

  IconData _getClientStatusIcon(ClientConnectionStatus status) {
    switch (status) {
      case ClientConnectionStatus.disconnected:
        return Icons.devices_other;
      case ClientConnectionStatus.connected:
        return Icons.phone_iphone;
    }
  }

  Color _getClientStatusColor(ClientConnectionStatus status) {
    switch (status) {
      case ClientConnectionStatus.disconnected:
        return kTextSecondary;
      case ClientConnectionStatus.connected:
        return kSuccessColor;
    }
  }

  Widget _buildEditorTab(HomeState state, HomeViewModel notifier) {
    return Column(
      children: [
        Expanded(
          child: _buildEditor(state),
        ),
        _buildEditorBottomBar(state, notifier),
      ],
    );
  }

  Widget _buildEditor(HomeState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CodeEditor(
          controller: _editorController,
          readOnly: state.requestQueue.isEmpty,
          style: CodeEditorStyle(
            fontSize: 14,
            codeTheme: CodeHighlightTheme(
              languages: {
                'json': CodeHighlightThemeMode(
                  mode: langJson,
                ),
              },
              theme: atomOneLightTheme,
            ),
          ),
          indicatorBuilder: (context, editingController, chunkController, notifier) {
            return Row(
              children: [
                DefaultCodeLineNumber(
                  controller: editingController,
                  notifier: notifier,
                ),
                DefaultCodeChunkIndicator(
                  width: 20,
                  controller: chunkController,
                  notifier: notifier,
                ),
              ],
            );
          },
          onChanged: (value) {
            ref.read(homeViewModelProvider.notifier).updateJsonText(_editorController.text);
          },
        ),
      ),
    );
  }

  Widget _buildEditorBottomBar(HomeState state, HomeViewModel notifier) {
    final statusColor = _getStatusColor(state.currentStatus);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 状态指示
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(state.currentStatus),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getStatusText(state.currentStatus, state.requestQueue.length),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 放行按钮
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: state.requestQueue.isNotEmpty
                  ? () {
                      try {
                        notifier.handleSave();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('JSON 格式错误，请检查！错误信息: $e'),
                            backgroundColor: kErrorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.send, size: 20,color: Colors.white),
              label: const Text('放行'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kTextSecondary.withOpacity(0.2),
                disabledForegroundColor: kTextSecondary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InterceptStatus status) {
    switch (status) {
      case InterceptStatus.waiting:
        return kSuccessColor;
      case InterceptStatus.blocked:
        return kErrorColor;
      case InterceptStatus.released:
        return kWarningColor;
    }
  }

  IconData _getStatusIcon(InterceptStatus status) {
    switch (status) {
      case InterceptStatus.waiting:
        return Icons.check_circle_outline;
      case InterceptStatus.blocked:
        return Icons.block;
      case InterceptStatus.released:
        return Icons.send;
    }
  }

  String _getStatusText(InterceptStatus status, int queueLength) {
    switch (status) {
      case InterceptStatus.waiting:
        return '等待拦截请求...';
      case InterceptStatus.blocked:
        return '已拦截 (队列中还有 $queueLength 个请求)';
      case InterceptStatus.released:
        return '数据已放行';
    }
  }
}
