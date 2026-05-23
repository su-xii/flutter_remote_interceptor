import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import '../providers.dart';
import '../widgets/request_list_page.dart';
import '../widgets/server_status_indicator.dart';
import '../state/home_state.dart';
import '../state/server_state.dart';
import '../viewmodel/home_viewmodel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CodeLineEditingController _editorController = CodeLineEditingController();
  
  StreamController<ServerStatus>? _serverStatusController;
  StreamController<ClientConnectionStatus>? _clientStatusController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _serverStatusController = StreamController<ServerStatus>.broadcast();
    _clientStatusController = StreamController<ClientConnectionStatus>.broadcast();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gHomeViewModelProvider.notifier).onViewInit();
    });
  }

  @override
  void dispose() {
    ref.read(gHomeViewModelProvider.notifier).onViewDispose();
    _tabController.dispose();
    _serverStatusController?.close();
    _clientStatusController?.close();
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gHomeViewModelProvider);
    final wsServer = ref.watch(gWsServerProvider);
    final notifier = ref.read(gHomeViewModelProvider.notifier);
    
    wsServer.onStatusChanged = (status) {
      _serverStatusController?.add(status);
    };
    wsServer.onClientStatusChanged = (status) {
      _clientStatusController?.add(status);
    };

    if (state.currentJsonText.isNotEmpty && _editorController.text != state.currentJsonText) {
      _editorController.text = state.currentJsonText;
    }

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
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('切换设备'),
                  content: const Text('确定要断开当前连接并选择其他设备吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        notifier.navigateToDeviceDiscovery();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
            tooltip: '切换设备',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<ServerStatus>(
                  stream: _serverStatusController?.stream,
                  initialData: wsServer.status,
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
                StreamBuilder<ClientConnectionStatus>(
                  stream: _clientStatusController?.stream,
                  initialData: wsServer.clientStatus,
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
          _buildEditorTab(state, notifier),
          const RequestListPage(),
        ],
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
        return Colors.orange;
      case ServerStatus.running:
        return Colors.green;
      case ServerStatus.stopped:
        return Colors.grey;
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
        return Colors.grey;
      case ClientConnectionStatus.connected:
        return Colors.green;
    }
  }

  Widget _buildEditorTab(HomeState state, HomeViewModel notifier) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.isIntercepting
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isIntercepting ? Colors.orange : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state.isIntercepting
                            ? Icons.shield_outlined
                            : Icons.shield_outlined,
                        color: state.isIntercepting ? Colors.orange : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isIntercepting ? '拦截开启' : '拦截关闭',
                        style: TextStyle(
                          color: state.isIntercepting ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: state.isIntercepting,
                        onChanged: (value) {
                          notifier.toggleIntercepting(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: state.requestQueue.isNotEmpty
                    ? () {
                        try {
                          notifier.handleSave();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('JSON 格式错误，请检查！错误信息: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
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
                '支持多请求排队拦截，先到先处理。当前队列长度：${state.requestQueue.length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                ref.read(gHomeViewModelProvider.notifier).updateJsonText(_editorController.text);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _getStatusColor(state.currentStatus).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(state.currentStatus),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(state.currentStatus),
                  color: _getStatusColor(state.currentStatus),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getStatusText(state.currentStatus, state.requestQueue.length),
                    style: TextStyle(
                      color: _getStatusColor(state.currentStatus),
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
