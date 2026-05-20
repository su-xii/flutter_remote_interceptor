import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../viewmodel/home_viewmodel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final statusConfig = viewModel.getStatusConfig();

    // 同步 ViewModel 的文本到控制器（仅在文本变化时）
    if (_controller.text != viewModel.currentJsonText) {
      _controller.text = viewModel.currentJsonText;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON 拦截编辑器'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: viewModel.isIntercepting,
            onChanged: (value) {
              viewModel.toggleIntercepting(value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              try {
                viewModel.handleSave();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('JSON 格式错误，请检查！错误信息: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: '保存并放行当前请求',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '提示：支持多请求排队拦截，先到先处理。当前队列长度：${viewModel.queueLength}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  hintText: '等待拦截请求...',
                ),
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                onChanged: (text) {
                  viewModel.updateJsonText(text);
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: statusConfig['color'] as Color,
            child: Text(
              statusConfig['text'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
