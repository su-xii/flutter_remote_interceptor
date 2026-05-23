import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/widgets/request_detail_dialog.dart';

const Color kPrimaryColor = Color(0xFF165DFF);
const Color kSuccessColor = Color(0xFF00B42A);
const Color kWarningColor = Color(0xFFFF7D00);
const Color kErrorColor = Color(0xFFF53F3F);
const Color kTextPrimary = Color(0xFF1D2129);
const Color kTextSecondary = Color(0xFF86909C);
const Color kBgCard = Color(0xFFFFFFFF);
const Color kBgPage = Color(0xFFF2F3F5);

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
    final state = ref.watch(gHomeViewModelProvider);
    final records = state.requestRecords;

    // 当有新记录时，自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (records.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        _buildHeader(context, records.length),
        Expanded(
          child: records.isEmpty
              ? _buildEmptyState()
              : _buildRecordList(records),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int recordCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.list_alt,
                  size: 20,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '请求记录',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$recordCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          if (recordCount > 0)
            TextButton.icon(
              onPressed: () {
                // TODO: 清空记录
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('清空'),
              style: TextButton.styleFrom(
                foregroundColor: kErrorColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.history_toggle_off,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无请求记录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kTextPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '拦截请求后会在这里显示记录',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(List<RequestRecord> records) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _RequestRecordItem(
          record: record,
          index: index,
          onTap: () => _showRequestDetail(record),
        );
      },
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
  final int index;
  final VoidCallback onTap;

  const _RequestRecordItem({
    required this.record,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusInfo['icon'],
                    size: 22,
                    color: statusInfo['color'],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request #${index + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${record.requestId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusInfo['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusInfo['label'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusInfo['color'],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: kTextSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(record.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: kTextSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo() {
    IconData icon;
    Color color;
    String label;

    switch (record.state) {
      case InterceptState.notIntercepted:
        icon = Icons.check_circle;
        color = kSuccessColor;
        label = '未拦截';
        break;
      case InterceptState.interceptedPending:
        icon = Icons.pending_actions;
        color = kWarningColor;
        label = '等待处理';
        break;
      case InterceptState.interceptedProcessed:
        icon = Icons.done_all;
        color = kPrimaryColor;
        label = '已放行';
        break;
    }

    return {
      'icon': icon,
      'color': color,
      'label': label,
    };
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
