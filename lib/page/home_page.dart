import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

import '../providers.dart';
import '../viewmodel/home_viewmodel.dart';
import '../widgets/request_list_page.dart';
import '../widgets/server_status_indicator.dart';
import '../server/remote_server.dart';
import 'dart:async';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 状态监听器
  StreamController<ServerStatus>? _serverStatusController;
  StreamController<ClientConnectionStatus>? _clientStatusController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化状态监听器
    _serverStatusController = StreamController<ServerStatus>.broadcast();
    _clientStatusController = StreamController<ClientConnectionStatus>.broadcast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serverStatusController?.close();
    _clientStatusController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final statusConfig = viewModel.getStatusConfig();
    final server = ref.watch(remoteServerProvider);
    
    // 设置状态监听
    server.onStatusChanged = (status) {
      _serverStatusController?.add(status);
    };
    server.onClientStatusChanged = (status) {
      _clientStatusController?.add(status);
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON 拦截编辑器'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '当前请求', icon: Icon(Icons.edit)),
            Tab(text: '请求记录', icon: Icon(Icons.list)),
          ],
        ),
        actions: [
          // 服务端和客户端状态
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 服务端状态
                StreamBuilder<ServerStatus>(
                  stream: _serverStatusController?.stream,
                  initialData: server.status,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? ServerStatus.stopped;
                    return StatusIndicator(
                      label: _getServerStatusText(status),
                      icon: _getServerStatusIcon(status),
                      color: _getServerStatusColor(status),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // 客户端状态
                StreamBuilder<ClientConnectionStatus>(
                  stream: _clientStatusController?.stream,
                  initialData: server.clientStatus,
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? ClientConnectionStatus.disconnected;
                    return StatusIndicator(
                      label: _getClientStatusText(status),
                      icon: _getClientStatusIcon(status),
                      color: _getClientStatusColor(status),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 当前请求编辑器
          _buildEditorTab(viewModel, statusConfig),
          // Tab 2: 请求记录列表
          const RequestListPage(),
        ],
      ),
    );
  }
  
  /// 创建服务器状态监听器
  ValueNotifier<ServerStatus> _createServerStatusListener(RemoteServer server) {
    final notifier = ValueNotifier<ServerStatus>(server.status);
    server.onStatusChanged = (status) {
      notifier.value = status;
    };
    return notifier;
  }
  
  /// 获取状态颜色
  Color _getStatusColor(InterceptStatus status) {
    switch (status) {
      case InterceptStatus.waiting:
        return Colors.green;
      case InterceptStatus.blocked:
        return Colors.red;
      case InterceptStatus.released:
        return Colors.orange;
    }
  }
  
  /// 获取状态图标
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
  
  /// 获取状态文本
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
  
  // ========== 服务端状态 ==========
  
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
        return Colors.orange;
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.stopped:
        return Colors.grey;
    }
  }
  
  // ========== 客户端状态 ==========
  
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
        return Colors.grey;
      case ClientConnectionStatus.connected:
        return Colors.green;
    }
  }

  Widget _buildEditorTab(HomeViewModel viewModel, Map<String, dynamic> statusConfig) {
    return Column(
      children: [
        // 顶部控制栏
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              // 拦截开关
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: viewModel.isIntercepting 
                        ? Colors.orange.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: viewModel.isIntercepting ? Colors.orange : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        viewModel.isIntercepting 
                            ? Icons.shield_outlined 
                            : Icons.shield_outlined,
                        color: viewModel.isIntercepting ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        viewModel.isIntercepting ? '拦截开启' : '拦截关闭',
                        style: TextStyle(
                          color: viewModel.isIntercepting ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: viewModel.isIntercepting,
                        onChanged: (value) {
                          viewModel.toggleIntercepting(value);
                        },
                        activeColor: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 放行按钮
              ElevatedButton.icon(
                onPressed: viewModel.queueLength > 0 ? () {
                  try {
                    viewModel.handleSave();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('JSON 格式错误，请检查！错误信息: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } : null,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('放行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 队列提示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '支持多请求排队拦截，先到先处理。当前队列长度：${viewModel.queueLength}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        // JSON 编辑器
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CodeEditor(
              controller: viewModel.editorController,
              readOnly: viewModel.queueLength == 0,
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
                viewModel.updateJsonText(viewModel.editorController.text);
              },
            ),
          ),
        ),
        // 底部状态卡片
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(viewModel.currentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(viewModel.currentStatus),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(viewModel.currentStatus),
                  color: _getStatusColor(viewModel.currentStatus),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getStatusText(viewModel.currentStatus, viewModel.queueLength),
                    style: TextStyle(
                      color: _getStatusColor(viewModel.currentStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
