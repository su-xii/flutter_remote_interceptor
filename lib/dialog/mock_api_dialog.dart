import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/mock_rule_dialog.dart' show FullScreenEditor;
import 'package:remote_interceptor/model/mock_page.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';
import 'package:remote_interceptor/widgets/api_method_badge.dart';

/// 接口配置保存回调
typedef OnApiSave = void Function({
  required HttpMethod method,
  required String path,
  required String response,
  String? remark,
});

/// 新增 / 编辑「页面级 Mock」中的单个接口配置。
///
/// [api] 为 `null` 时表示新增，否则为编辑。
class MockApiDialog extends ConsumerStatefulWidget {
  final MockApiConfig? api;
  final OnApiSave onSave;

  const MockApiDialog({
    super.key,
    this.api,
    required this.onSave,
  });

  @override
  ConsumerState<MockApiDialog> createState() => _MockApiDialogState();
}

class _MockApiDialogState extends ConsumerState<MockApiDialog> {
  late TextEditingController _pathController;
  late TextEditingController _remarkController;
  late TextEditingController _responseController;
  late HttpMethod _selectedMethod;

  bool get _isEdit => widget.api != null;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.api?.path ?? '');
    _remarkController = TextEditingController(text: widget.api?.remark ?? '');
    _responseController = TextEditingController(
      text: widget.api?.response ?? '{\n  "code": 0,\n  "data": {}\n}',
    );
    _selectedMethod = widget.api?.method ?? HttpMethod.GET;
  }

  @override
  void dispose() {
    _pathController.dispose();
    _remarkController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  void _showResponseFullScreenEditor() {
    showDialog(
      context: context,
      builder: (context) => FullScreenEditor(
        controller: _responseController,
        title: 'Mock数据 - 全屏编辑',
      ),
    );
  }

  void _showTip(String message) {
    final colors = ref.read(themeProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleSave() {
    final path = _pathController.text.trim();
    final response = _responseController.text.trim();
    if (path.isEmpty) {
      _showTip('请输入接口路径');
      return;
    }
    if (response.isEmpty) {
      _showTip('请输入 Mock 数据');
      return;
    }
    // 必须是合法 JSON：否则运行时无法改写响应，提前拦截避免「配了但没效果」
    try {
      json.decode(response);
    } catch (e) {
      _showTip('Mock 数据不是合法 JSON: $e');
      return;
    }

    widget.onSave(
      method: _selectedMethod,
      path: path,
      response: response,
      remark: _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 620),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isEdit ? Icons.edit_note : Icons.add_box_outlined,
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
                                _isEdit ? '编辑接口Mock数据' : '添加接口Mock数据',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                '仅当前页面生效，接口以 路径 + 方法 匹配',
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
                    _buildLabel('HTTP 方法', colors),
                    const SizedBox(height: 8),
                    _buildMethodSelector(colors),
                    const SizedBox(height: 16),
                    _buildLabel('接口路径', colors),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _pathController,
                      hintText: '/api/user/profile',
                      colors: colors,
                      prefixIcon: Icons.link,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('备注（可选）', colors),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _remarkController,
                      hintText: '例如：用户信息',
                      colors: colors,
                      prefixIcon: Icons.sticky_note_2_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildLabel('Mock数据', colors)),
                        IconButton(
                          onPressed: _showResponseFullScreenEditor,
                          icon: const Icon(Icons.fullscreen, size: 20),
                          tooltip: '全屏编辑',
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _responseController,
                      hintText: '{"code": 0, "data": {}}',
                      colors: colors,
                      prefixIcon: Icons.code,
                      maxLines: 6,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.textSecondary.withOpacity(0.1)),
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

  Widget _buildLabel(String text, AppColors colors) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required AppColors colors,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: colors.textSecondary.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMethodSelector(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const Spacer(),
          DropdownButton<HttpMethod>(
            value: _selectedMethod,
            underline: const SizedBox(),
            items: HttpMethod.values.map((method) {
              final color = apiMethodColor(method);
              return DropdownMenuItem(
                value: method,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    method.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedMethod = value);
            },
          ),
        ],
      ),
    );
  }
}
