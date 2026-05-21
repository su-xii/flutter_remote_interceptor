import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:remote_interceptor/providers.dart';
import 'package:remote_interceptor/model/request_record.dart';

/// 请求详情弹窗
class RequestDetailDialog extends ConsumerStatefulWidget {
  final RequestRecord record;

  const RequestDetailDialog({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<RequestDetailDialog> createState() => _RequestDetailDialogState();
}

class _RequestDetailDialogState extends ConsumerState<RequestDetailDialog> {
  late CodeLineEditingController _controller;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    _controller = CodeLineEditingController.fromText(
      encoder.convert(widget.record.displayData),
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final isPending = widget.record.state == InterceptState.interceptedPending;

    return Dialog(
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '请求详情',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // 信息区域
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('记录 ID: ${widget.record.id}'),
                  Text('Request ID: ${widget.record.requestId}'),
                  Text('时间: ${_formatTime(widget.record.timestamp)}'),
                  const SizedBox(height: 8),
                  _buildStatusChip(widget.record.state),
                ],
              ),
            ),

            // JSON 编辑器
            Expanded(
              child: CodeEditor(
                controller: _controller,
                readOnly: !isPending,
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
                  setState(() {
                    _isModified = true;
                  });
                },
              ),
            ),

            // 底部按钮
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isModified ? _handleRelease : null,
                    icon: const Icon(Icons.send),
                    label: const Text('放行'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InterceptState state) {
    String label;
    Color color;

    switch (state) {
      case InterceptState.notIntercepted:
        label = '未拦截';
        color = Colors.green;
        break;
      case InterceptState.interceptedPending:
        label = '拦截未处理';
        color = Colors.orange;
        break;
      case InterceptState.interceptedProcessed:
        label = '拦截已处理';
        color = Colors.blue;
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }

  void _handleRelease() {
    try {
      // 解析 JSON
      final modifiedData = json.decode(_controller.text) as Map<String, dynamic>;

      // 调用 ViewModel 放行
      final viewModel = ref.read(homeViewModelProvider);
      viewModel.releaseRequestById(widget.record.id, modifiedData);

      // 关闭弹窗
      Navigator.of(context).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请求已放行'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JSON 格式错误: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
