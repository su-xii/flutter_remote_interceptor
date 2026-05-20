import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/model/request_record.dart';

// 拦截队列中的单个任务单元
class InterceptTask {
  final String requestId;
  final String jsonData; // 暂存该请求的原始 JSON 字符串
  final Completer<Map<String, dynamic>> completer;

  InterceptTask(this.requestId, this.jsonData, this.completer);
}

// 拦截状态枚举
enum InterceptStatus {
  waiting,
  blocked,
  released
}

class HomeViewModel extends ChangeNotifier {
  final RemoteServer _server;
  
  // 请求拦截队列（FIFO 先进先出）
  final List<InterceptTask> _requestQueue = [];
  
  // 所有请求记录列表
  final List<RequestRecord> _requestRecords = [];

  // 当前拦截状态
  InterceptStatus _currentStatus = InterceptStatus.waiting;

  // 是否开启拦截
  bool _isIntercepting = true;

  // 当前显示的 JSON 文本
  String _currentJsonText = '';
  
  // 计数器，用于生成唯一 ID
  int _recordCounter = 0;

  HomeViewModel(this._server) {
    // 设置请求处理器
    _server.requestHandler = _handleRequest;
    // 注意：Server 的启动由 App 生命周期管理，不在 ViewModel 中启动
  }

  // Getters
  InterceptStatus get currentStatus => _currentStatus;
  bool get isIntercepting => _isIntercepting;
  String get currentJsonText => _currentJsonText;
  int get queueLength => _requestQueue.length;
  List<RequestRecord> get requestRecords => List.unmodifiable(_requestRecords);

  // 获取状态配置信息
  Map<String, dynamic> getStatusConfig() {
    final int queueLength = _requestQueue.length;
    switch (_currentStatus) {
      case InterceptStatus.waiting:
        return {'text': '🟢 状态：等待拦截请求...', 'color': Colors.green};
      case InterceptStatus.blocked:
        return {'text': '🔴 状态：已拦截 (队列中还有 $queueLength 个请求)', 'color': Colors.red};
      case InterceptStatus.released:
        return {'text': '🟡 状态：数据已放行', 'color': Colors.orange};
    }
  }

  // 1. WebSocket 收到请求时的处理函数
  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> requestData) async {
    // 生成唯一 ID
    _recordCounter++;
    final String recordId = 'req_$_recordCounter';
    final String requestId = requestData['requestId']?.toString() ?? 'unknown';
    
    // 创建请求记录
    final record = RequestRecord(
      id: recordId,
      requestId: requestId,
      originalData: Map<String, dynamic>.from(requestData),
      timestamp: DateTime.now(),
      state: _isIntercepting ? InterceptState.interceptedPending : InterceptState.notIntercepted,
    );
    
    _requestRecords.add(record);
    notifyListeners();
    
    if (!_isIntercepting) {
      // 如果未开启拦截，直接放行
      return requestData;
    }

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String jsonText = encoder.convert(requestData);

    // 创建 Completer 并加入队列
    final completer = Completer<Map<String, dynamic>>();
    _requestQueue.add(InterceptTask(recordId, jsonText, completer));

    // 如果是第一个请求，立刻更新 UI 展示它的数据
    if (_requestQueue.length == 1) {
      _currentStatus = InterceptStatus.blocked;
      _currentJsonText = jsonText;
      notifyListeners();
    }

    // 当前请求在此处阻塞，等待队列轮到自己被 complete
    final modifiedData = await completer.future;
    
    // 更新记录状态为已处理
    final recordIndex = _requestRecords.indexWhere((r) => r.id == recordId);
    if (recordIndex != -1) {
      _requestRecords[recordIndex].state = InterceptState.interceptedProcessed;
      _requestRecords[recordIndex].modifiedData = modifiedData;
      notifyListeners();
    }
    
    return modifiedData;
  }

  // 2. 点击保存按钮，放行队列中的第一个请求
  void handleSave() {
    if (_requestQueue.isEmpty) return;

    try {
      // 将输入框的 JSON 字符串转回 Map
      Map<String, dynamic> modifiedData = json.decode(_currentJsonText) as Map<String, dynamic>;

      // 【核心放行】取出队列的第一个任务，触发它的 completer
      final firstTask = _requestQueue.removeAt(0);
      firstTask.completer.complete(modifiedData);

      // 放行后，检查队列里是否还有下一个请求
      if (_requestQueue.isNotEmpty) {
        // 如果有，自动把下一个请求的原始数据显示在输入框中，等待处理
        _currentStatus = InterceptStatus.blocked;
        _currentJsonText = _requestQueue.first.jsonData;
      } else {
        // 如果队列为空，恢复等待状态
        _currentStatus = InterceptStatus.waiting;
        _currentJsonText = '';
      }
      
      notifyListeners();

    } catch (e) {
      // 错误处理需要在 UI 层进行，这里抛出异常
      rethrow;
    }
  }
  
  // 3. 放行指定 ID 的请求（从列表中）
  void releaseRequestById(String recordId, Map<String, dynamic> modifiedData) {
    final queueIndex = _requestQueue.indexWhere((task) => task.requestId == recordId);
    
    if (queueIndex != -1) {
      // 在队列中找到，放行它
      final task = _requestQueue[queueIndex];
      task.completer.complete(modifiedData);
      _requestQueue.removeAt(queueIndex);
      
      // 更新记录状态
      final recordIndex = _requestRecords.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        _requestRecords[recordIndex].state = InterceptState.interceptedProcessed;
        _requestRecords[recordIndex].modifiedData = modifiedData;
      }
      
      // 如果当前正在编辑的是这个请求，更新显示
      if (_requestQueue.isNotEmpty && _requestQueue.first.requestId == recordId) {
        _currentStatus = InterceptStatus.blocked;
        _currentJsonText = _requestQueue.first.jsonData;
      } else if (_requestQueue.isEmpty) {
        _currentStatus = InterceptStatus.waiting;
        _currentJsonText = '';
      }
      
      notifyListeners();
    }
  }

  // 切换拦截开关
  void toggleIntercepting(bool value) {
    _isIntercepting = value;
    notifyListeners();
  }

  // 更新 JSON 文本
  void updateJsonText(String text) {
    _currentJsonText = text;
    notifyListeners();
  }

  @override
  void dispose() {
    // 注意：不再在 ViewModel 中销毁 Server，由 App 生命周期统一管理
    super.dispose();
  }
}