import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/mock_rule_dialog.dart';
import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';

const Color kPrimaryColor = Color(0xFF165DFF);
const Color kSuccessColor = Color(0xFF00B42A);
const Color kWarningColor = Color(0xFFFF7D00);
const Color kErrorColor = Color(0xFFF53F3F);
const Color kTextPrimary = Color(0xFF1D2129);
const Color kTextSecondary = Color(0xFF86909C);
const Color kBgCard = Color(0xFFFFFFFF);
const Color kBgPage = Color(0xFFF2F3F5);

class MockResponsePage extends ConsumerStatefulWidget {
  const MockResponsePage({super.key});

  @override
  ConsumerState createState() => _MockResponsePageState();
}

class _MockResponsePageState extends ConsumerState<MockResponsePage> {
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => MockRuleDialog(
        onSave: (
            {required String url,
            required HttpMethod method,
            required String mockData,
            required bool enabled,
            String? id}) {
          ref.read(mockResponseViewModelProvider.notifier).addRule(
                url: url,
                method: method,
                mockData: mockData,
                enabled: enabled,
              );
        },
      ),
    );
  }

  void _showEditDialog(MockRule rule) {
    showDialog(
      context: context,
      builder: (context) => MockRuleDialog(
        rule: rule,
        onSave: (
            {required String url,
            required HttpMethod method,
            required String mockData,
            required bool enabled,
            String? id}) {
          if (id != null) {
            ref.read(mockResponseViewModelProvider.notifier).updateRule(
                  id: id,
                  url: url,
                  method: method,
                  mockData: mockData,
                  enabled: enabled,
                );
          }
        },
      ),
    );
  }

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
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
                  color: kErrorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 40,
                  color: kErrorColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '确认删除',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '确定要删除这条Mock规则吗？',
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
                        ref.read(mockResponseViewModelProvider.notifier).deleteRule(id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kErrorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '删除',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockRules = ref.watch(mockResponseViewModelProvider).mockRules;

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: const Text(
          'Mock规则管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: mockRules.isEmpty
          ? _buildEmptyState()
          : _buildRuleList(mockRules),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
              Icons.rule_folder_outlined,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无Mock规则',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kTextPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加Mock规则',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleList(List<MockRule> mockRules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockRules.length,
      itemBuilder: (context, index) {
        final rule = mockRules[index];
        return _MockRuleItem(
          rule: rule,
          onEdit: () => _showEditDialog(rule),
          onDelete: () => _handleDelete(rule.id),
        );
      },
    );
  }
}

class _MockRuleItem extends StatelessWidget {
  final MockRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MockRuleItem({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final methodColor = _getMethodColor();
    
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
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 启用/禁用状态指示
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: rule.enabled
                        ? kSuccessColor.withOpacity(0.1)
                        : kTextSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    rule.enabled ? Icons.check_circle : Icons.pause_circle,
                    size: 22,
                    color: rule.enabled ? kSuccessColor : kTextSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                // 内容区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // URL
                      Text(
                        rule.url,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // 底部信息
                      Row(
                        children: [
                          // HTTP 方法标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: methodColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rule.method.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: methodColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 状态
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: rule.enabled
                                  ? kSuccessColor.withOpacity(0.1)
                                  : kTextSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rule.enabled ? '已启用' : '已禁用',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: rule.enabled
                                    ? kSuccessColor
                                    : kTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 命中次数
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: kTextSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "命中 ${rule.hitCount} 次",
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: kPrimaryColor,
                      onPressed: onEdit,
                      tooltip: '编辑',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: kErrorColor,
                      onPressed: onDelete,
                      tooltip: '删除',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMethodColor() {
    switch (rule.method) {
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
}
