import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/widgets/request_detail_dialog.dart';

/// 请求记录列表页面
class RequestListPage extends ConsumerStatefulWidget {
  const RequestListPage({super.key});

  @override
  ConsumerState<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends ConsumerState<RequestListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动事件，判断是否在底部
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      // 距离底部 100px 以内，认为在底部
      _shouldAutoScroll = true;
    } else {
      _shouldAutoScroll = false;
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    if (_shouldAutoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final records = state.requestRecords;

    // 当有新记录时，自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (records.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '请求记录 (${records.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (records.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: 清空记录
                  },
                  child: const Text('清空'),
                ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(
                  child: Text(
                    '暂无请求记录',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _RequestRecordItem(
                      record: record,
                      onTap: () => _showRequestDetail(record),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 显示请求详情弹窗
  void _showRequestDetail(RequestRecord record) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(record: record),
    );
  }
}

/// 单个请求记录项
class _RequestRecordItem extends StatelessWidget {
  final RequestRecord record;
  final VoidCallback onTap;

  const _RequestRecordItem({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text('Request ID: ${record.requestId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('记录 ID: ${record.id}'),
            Text(
              '时间: ${_formatTime(record.timestamp)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (record.state) {
      case InterceptState.notIntercepted:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case InterceptState.interceptedPending:
        icon = Icons.pending_actions;
        color = Colors.orange;
        break;
      case InterceptState.interceptedProcessed:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
    }

    return Icon(icon, color: color);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
