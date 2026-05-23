import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/providers.dart';
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

  // 临时模拟数据
  List<RequestRecord> get _mockRecords {
    final now = DateTime.now();
    return [
      RequestRecord(
        id: '1',
        requestId: 'req_001',
        originalData: {'data': 'test1'},
        timestamp: now.subtract(const Duration(minutes: 5, seconds: 30)),
        url: 'http://www.52im.net/portal/api/v1/posts',
        method: HttpMethod.GET,
        statusCode: 200,
        contentType: 'HTML',
        duration: 156,
      ),
      RequestRecord(
        id: '2',
        requestId: 'req_002',
        originalData: {'data': 'test2'},
        timestamp: now.subtract(const Duration(minutes: 5, seconds: 20)),
        url: 'https://clientservices.googleapis.com/v2/messaging',
        method: HttpMethod.POST,
        statusCode: 200,
        contentType: 'TEXT',
        duration: 148,
      ),
      RequestRecord(
        id: '3',
        requestId: 'req_003',
        originalData: {'data': 'test3'},
        timestamp: now.subtract(const Duration(minutes: 5, seconds: 10)),
        url: 'http://www.52im.net/portal/api/v1/users',
        method: HttpMethod.GET,
        statusCode: 200,
        contentType: 'HTML',
        duration: 231,
      ),
      RequestRecord(
        id: '4',
        requestId: 'req_004',
        originalData: {'data': 'test4'},
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 50)),
        url: 'https://clientservices.googleapis.com/v2/connect',
        method: HttpMethod.POST,
        statusCode: 200,
        contentType: 'TEXT',
        duration: 160,
      ),
      RequestRecord(
        id: '5',
        requestId: 'req_005',
        originalData: {'data': 'test5'},
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 30)),
        url: 'https://api.example.com/v3/data',
        method: HttpMethod.PUT,
        statusCode: 404,
        contentType: 'JSON',
        duration: 450,
      ),
      RequestRecord(
        id: '6',
        requestId: 'req_006',
        originalData: {'data': 'test6'},
        timestamp: now.subtract(const Duration(minutes: 4, seconds: 10)),
        url: 'https://api.example.com/v3/files',
        method: HttpMethod.DELETE,
        statusCode: 204,
        contentType: 'JSON',
        duration: 89,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // 临时使用模拟数据渲染
    final records = _mockRecords;
    
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
    final methodColor = _getMethodColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HTTP 方法标签
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: methodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getMethodLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: methodColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 中间内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // URL
                    Text(
                      _truncateUrl(record.url),
                      style: const TextStyle(
                        fontSize: 15,
                        color: kTextPrimary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 底部信息
                    Row(
                      children: [
                      // 时间
                      Text(
                        _formatTime(record.timestamp),
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary.withOpacity(0.8),
                        ),
                      ),
                      // 分隔符
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: kTextSecondary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // 状态码
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusCodeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${record.statusCode}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusCodeColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 内容类型
                      Text(
                        record.contentType,
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 响应时间
                      Text(
                        '${record.duration}ms',
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 右侧箭头
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: kTextSecondary.withOpacity(0.4),
            ),
          ],
        ),
      ),
    )));
  }

  Color _getMethodColor() {
    switch (record.method) {
      case HttpMethod.GET:
        return const Color(0xFF3B82F6); // 蓝色
      case HttpMethod.POST:
        return const Color(0xFF10B981); // 绿色
      case HttpMethod.PUT:
        return const Color(0xFFF59E0B); // 黄色
      case HttpMethod.DELETE:
        return const Color(0xFFEF4444); // 红色
      case HttpMethod.PATCH:
        return const Color(0xFF8B5CF6); // 紫色
      default:
        return kTextSecondary;
    }
  }

  String _getMethodLabel() {
    return record.method.toString().split('.').last;
  }

  Color _getStatusCodeColor() {
    if (record.statusCode >= 200 && record.statusCode < 300) {
      return kSuccessColor;
    } else if (record.statusCode >= 300 && record.statusCode < 400) {
      return kWarningColor;
    } else {
      return kErrorColor;
    }
  }

  String _truncateUrl(String url) {
    if (url.length <= 50) return url;
    // 保留域名和部分路径
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return '${uri.scheme}://${uri.host}${uri.path.length > 20 ? '...' : uri.path}';
    }
    return url.substring(0, 47) + '...';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
