import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/mock_rule_dialog.dart';
import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条Mock规则吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(mockResponseViewModelProvider.notifier).deleteRule(id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockRules = ref.watch(mockResponseViewModelProvider).mockRules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock规则管理'),
      ),
      body: mockRules.isEmpty
          ? const Center(
              child: Text('暂无Mock规则，点击下方按钮添加'),
            )
          : ListView.builder(
              itemCount: mockRules.length,
              itemBuilder: (context, index) {
                final rule = mockRules[index];
                return ListTile(
                  title: Text(rule.url),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rule.method.name,
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(rule.enabled ? '已启用' : '已禁用'),
                      const SizedBox(width: 8),
                      Text("命中次数:${rule.hitCount}")
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(rule),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _handleDelete(rule.id),
                      ),
                    ],
                  ),
                  onTap: () => _showEditDialog(rule),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
