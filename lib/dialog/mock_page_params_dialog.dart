import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/mock_rule_dialog.dart' show FullScreenEditor;
import 'package:remote_interceptor/providers/theme_provider.dart';

/// 路由入参保存回调
typedef OnRouteParamsSave = void Function(Map<String, dynamic> routeParams);

/// 编辑「页面级 Mock」路由入参的弹窗。
///
/// 入参以 JSON 对象形式编辑，同时作为跳转指令的 `arguments` 下发；
/// 内容清空表示该页面无路由入参。
class MockPageParamsDialog extends ConsumerStatefulWidget {
  /// 已有的路由入参（可能为空）
  final Map<String, dynamic> params;

  final OnRouteParamsSave onSave;

  const MockPageParamsDialog({
    super.key,
    required this.params,
    required this.onSave,
  });

  @override
  ConsumerState<MockPageParamsDialog> createState() =>
      _MockPageParamsDialogState();
}

class _MockPageParamsDialogState extends ConsumerState<MockPageParamsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _initialText());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 初始文本：把已有入参格式化为缩进 JSON，便于直接修改
  String _initialText() {
    if (widget.params.isEmpty) return '';
    try {
      return const JsonEncoder.withIndent('  ').convert(widget.params);
    } catch (_) {
      return '';
    }
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

  void _showFullScreenEditor() {
    showDialog(
      context: context,
      builder: (context) => FullScreenEditor(
        controller: _controller,
        title: '路由入参 - 全屏编辑',
      ),
    );
  }

  void _handleSave() {
    final text = _controller.text.trim();

    // 清空表示「无路由入参」
    if (text.isEmpty) {
      widget.onSave(const <String, dynamic>{});
      Navigator.pop(context);
      return;
    }

    dynamic decoded;
    try {
      decoded = json.decode(text);
    } catch (e) {
      _showTip('不是合法 JSON: $e');
      return;
    }
    if (decoded is! Map) {
      _showTip('路由入参必须是 JSON 对象，例如 {"userId": "12345"}');
      return;
    }

    widget.onSave(decoded.cast<String, dynamic>());
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
        padding: const EdgeInsets.all(24),
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
                  child:
                      Icon(Icons.list_alt, size: 24, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '编辑路由入参',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '会在「进入页面」时作为 arguments 下发给被调试端',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showFullScreenEditor,
                  icon: const Icon(Icons.fullscreen, size: 22),
                  tooltip: '全屏编辑',
                  color: colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{\n  "userId": "12345"\n}',
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
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '留空表示无路由入参',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }
}
