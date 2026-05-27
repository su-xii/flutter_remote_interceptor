import 'package:flutter/material.dart';
import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:remote_interceptor/model/request_record.dart';

typedef OnSave = void Function({
  required String url,
  required HttpMethod method,
  required String mockData,
  required bool enabled,
  String? id,
});

class MockRuleDialog extends StatefulWidget {
  final MockRule? rule;
  final OnSave onSave;

  const MockRuleDialog({
    super.key,
    this.rule,
    required this.onSave,
  });

  @override
  State<MockRuleDialog> createState() => _MockRuleDialogState();
}

class _MockRuleDialogState extends State<MockRuleDialog> {
  late TextEditingController _urlController;
  late TextEditingController _mockDataController;
  late HttpMethod _selectedMethod;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _urlController = TextEditingController(text: widget.rule!.url);
      _mockDataController = TextEditingController(text: widget.rule!.mockData);
      _selectedMethod = widget.rule!.method;
      _enabled = widget.rule!.enabled;
    } else {
      _urlController = TextEditingController();
      _mockDataController = TextEditingController();
      _selectedMethod = HttpMethod.GET;
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _mockDataController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入URL')),
      );
      return;
    }
    if (_mockDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入Mock数据')),
      );
      return;
    }
    widget.onSave(
      url: _urlController.text,
      method: _selectedMethod,
      mockData: _mockDataController.text,
      enabled: _enabled,
      id: widget.rule?.id,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rule != null;
    return AlertDialog(
      title: Text(isEdit ? '编辑Mock规则' : '添加Mock规则'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://api.web.com/test',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HttpMethod>(
              value: _selectedMethod,
              items: HttpMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMethod = value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'HTTP方法',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mockDataController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mock数据',
                hintText: '{"code": 200, "data": {}}',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('启用规则'),
                Switch(
                  value: _enabled,
                  onChanged: (value) {
                    setState(() => _enabled = value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _handleSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
