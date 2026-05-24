import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';
import 'package:remote_interceptor/providers/providers.dart';
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
    final isPending = widget.record.state == InterceptState.interceptedPending;
    final statusInfo = _getStatusInfo(widget.record.state);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(maxWidth: 900),
        decoration: BoxDecoration(
          color: kBgCard,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: kTextSecondary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description,
                      size: 22,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '请求详情',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                        Text(
                          'Request ID: ${widget.record.requestId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: kTextSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusInfo['icon'],
                          size: 16,
                          color: statusInfo['color'],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusInfo['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusInfo['color'],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: kTextSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),

            // 信息区域
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBgPage,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      Icons.numbers,
                      '记录 ID',
                      widget.record.id,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.access_time,
                      '时间',
                      _formatTime(widget.record.timestamp),
                    ),
                  ],
                ),
              ),
            ),

            // JSON 编辑器
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: kTextSecondary.withOpacity(0.15),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                ),
              ),
            ),

            // 底部按钮
            if (isPending) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: kTextSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _handleRelease,
                      icon: const Icon(Icons.send, size: 18,color: Colors.white),
                      label: const Text('放行'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccessColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: kTextSecondary.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: kTextSecondary.withOpacity(0.8),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(InterceptState state) {
    IconData icon;
    Color color;
    String label;

    switch (state) {
      case InterceptState.notIntercepted:
        icon = Icons.check_circle;
        color = kSuccessColor;
        label = '未拦截';
        break;
      case InterceptState.interceptedPending:
        icon = Icons.pending_actions;
        color = kWarningColor;
        label = '拦截未处理';
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

  void _handleRelease() {
    try {
      // 解析 JSON
      final modifiedData = json.decode(_controller.text) as Map<String, dynamic>;

      // 调用 ViewModel 放行
      final notifier = ref.read(homeViewModelProvider.notifier);
      notifier.releaseRequestById(widget.record.id, modifiedData);

      // 关闭弹窗
      Navigator.of(context).pop();

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请求已放行'),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('JSON 格式错误: $e'),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
