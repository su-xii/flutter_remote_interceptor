import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';

typedef OnSave = void Function({
  required String url,
  required HttpMethod method,
  required String mockData,
  required bool enabled,
  String? remark,
  String? id,
  Map<String, dynamic>? requestParam,
});

class MockRuleDialog extends ConsumerStatefulWidget {
  final MockRule? rule;
  final OnSave onSave;

  const MockRuleDialog({
    super.key,
    this.rule,
    required this.onSave,
  });

  @override
  ConsumerState<MockRuleDialog> createState() => _MockRuleDialogState();
}

class _MockRuleDialogState extends ConsumerState<MockRuleDialog> {
  late TextEditingController _urlController;
  late TextEditingController _mockDataController;
  late TextEditingController _remarkController;
  late TextEditingController _requestParamController;
  late HttpMethod _selectedMethod;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _urlController = TextEditingController(text: widget.rule!.url);
      _mockDataController = TextEditingController(text: widget.rule!.mockData);
      _remarkController = TextEditingController(text: widget.rule!.remark);
      _requestParamController = TextEditingController(
        text: widget.rule!.requestParam != null
            ? json.encode(widget.rule!.requestParam)
            : null,
      );
      _selectedMethod = widget.rule!.method;
      _enabled = widget.rule!.enabled;
    } else {
      _urlController = TextEditingController();
      _mockDataController = TextEditingController();
      _remarkController = TextEditingController();
      _requestParamController = TextEditingController();
      _selectedMethod = HttpMethod.GET;
      _enabled = true;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _mockDataController.dispose();
    _remarkController.dispose();
    _requestParamController.dispose();
    super.dispose();
  }

  void _showMockDataFullScreenEditor() {
    showDialog(
      context: context,
      builder: (context) => FullScreenEditor(
        controller: _mockDataController,
        title: 'Mock数据 - 全屏编辑',
      ),
    );
  }

  void _showRequestParamFullScreenEditor() {
    showDialog(
      context: context,
      builder: (context) => FullScreenEditor(
        controller: _requestParamController,
        title: '请求参数 - 全屏编辑',
      ),
    );
  }

  void _handleSave() {
    final colors = ref.read(themeProvider);
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请输入URL'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (_mockDataController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请输入Mock数据'),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Map<String, dynamic>? parseRequestParam() {
      final paramText = _requestParamController.text.trim();
      if (paramText.isEmpty) {
        return null;
      }
      try {
        return json.decode(paramText) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    widget.onSave(
      url: _urlController.text,
      method: _selectedMethod,
      mockData: _mockDataController.text,
      enabled: _enabled,
      remark: _remarkController.text.isEmpty ? null : _remarkController.text,
      id: widget.rule?.id,
      requestParam: parseRequestParam(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);
    final isEdit = widget.rule != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 内容区域（可滚动）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题区域
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_note : Icons.add_box_outlined,
                            size: 24,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? '编辑Mock规则' : '添加Mock规则',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                isEdit ? '修改已有的Mock规则配置' : '创建新的Mock规则',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 表单内容
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 备注输入框
                        TextFormField(
                          controller: _remarkController,
                          decoration: InputDecoration(
                            labelText: '备注（可选）',
                            hintText: '例如：用户登录成功',
                            prefixIcon: const Icon(Icons.sticky_note_2_outlined,
                                size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.textSecondary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // URL 输入框
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'URL',
                            hintText: 'https://api.web.com/test',
                            prefixIcon: const Icon(Icons.link, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.textSecondary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // HTTP 方法选择
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.bgPage,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.textSecondary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.http, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'HTTP 方法',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              DropdownButton<HttpMethod>(
                                value: _selectedMethod,
                                underline: const SizedBox(),
                                items: HttpMethod.values.map((method) {
                                  return DropdownMenuItem(
                                    value: method,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getMethodColor(method)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        method.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _getMethodColor(method),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedMethod = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 请求参数输入框（可选）
                        Container(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '请求参数（可选）',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        _showRequestParamFullScreenEditor,
                                    icon:
                                        const Icon(Icons.fullscreen, size: 20),
                                    tooltip: '全屏编辑',
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _requestParamController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: '{"pageNum": 1, "pageSize": 50}',
                                  prefixIcon:
                                      const Icon(Icons.list_alt, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color:
                                          colors.textSecondary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mock 数据输入框
                        Container(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mock数据',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _showMockDataFullScreenEditor,
                                    icon:
                                        const Icon(Icons.fullscreen, size: 20),
                                    tooltip: '全屏编辑',
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _mockDataController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: '{"code": 200, "data": {}}',
                                  prefixIcon: const Icon(Icons.code, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color:
                                          colors.textSecondary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 启用开关
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.bgPage,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.textSecondary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _enabled
                                      ? colors.success.withOpacity(0.1)
                                      : colors.textSecondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _enabled
                                      ? Icons.check_circle
                                      : Icons.pause_circle,
                                  size: 20,
                                  color: _enabled
                                      ? colors.success
                                      : colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '启用规则',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: _enabled,
                                  onChanged: (value) {
                                    setState(() => _enabled = value);
                                  },
                                  activeColor: colors.success,
                                  activeTrackColor:
                                      colors.success.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 按钮区域（固定在底部）
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.textSecondary.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
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
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMethodColor(HttpMethod method) {
    switch (method) {
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
        final colors = ref.read(themeProvider);
        return colors.textSecondary;
    }
  }
}

class FullScreenEditor extends ConsumerWidget {
  final TextEditingController controller;
  final String title;

  const FullScreenEditor({
    super.key,
    required this.controller,
    this.title = '全屏编辑',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: colors.bgPage,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                border: Border(
                  bottom: BorderSide(
                    color: colors.textSecondary.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24),
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: TextFormField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: '{"code": 200, "data": {}}',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textPrimary,
                      fontFamily: 'Monaco, Menlo, monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
