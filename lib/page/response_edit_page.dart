import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/state/response_edit_state.dart';
import 'package:remote_interceptor/viewmodel/response_edit_viewmodel.dart';
import '../state/server_status_state.dart';
import '../widgets/request_list_page.dart';

const Color kPrimaryColor = Color(0xFF165DFF);
const Color kSuccessColor = Color(0xFF00B42A);
const Color kWarningColor = Color(0xFFFF7D00);
const Color kErrorColor = Color(0xFFF53F3F);
const Color kTextPrimary = Color(0xFF1D2129);
const Color kTextSecondary = Color(0xFF86909C);
const Color kBgCard = Color(0xFFFFFFFF);
const Color kBgPage = Color(0xFFF2F3F5);
const Color kBorderLight = Color(0xFFE5E6EB);

class ResponseEditPage extends ConsumerStatefulWidget {
  const ResponseEditPage({super.key});

  @override
  ConsumerState<ResponseEditPage> createState() => _ResponseEditPage();
}

class _ResponseEditPage extends ConsumerState<ResponseEditPage> with SingleTickerProviderStateMixin {
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

  late ResponseEditState state;
  late ResponseEditViewModel notifier;

  @override
  Widget build(BuildContext context) {
    state = ref.watch(responseEditViewModelProvider);
    notifier = ref.read(responseEditViewModelProvider.notifier);

    if (state.currentJsonText.isNotEmpty && _editorController.text != state.currentJsonText) {
      _editorController.text = state.currentJsonText;
    }

    return Scaffold(
      body: Column(
        children: [
          // 全局控制栏 - 始终可见
          _buildGlobalControlBar(),
          // Tab导航
          _buildTabBar(),
          // 内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditorTab(),
                const RequestListPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalControlBar() {
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

  Widget _buildEditorTab() {
    return Column(
      children: [
        Expanded(
          child: _buildEditor(),
        ),
        _buildEditorBottomBar(),
      ],
    );
  }

  Widget _buildEditor() {
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
            notifier.updateJsonText(_editorController.text);
          },
        ),
      ),
    );
  }

  Widget _buildEditorBottomBar() {
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
              icon: Icon(Icons.send,
                  size: 20,
                  color: state.requestQueue.isNotEmpty ? Colors.white : null),
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
