import 'dart:async';

// 拦截队列中的单个任务单元
class InterceptTask {
  final String requestId;
  final String jsonData; // 暂存该请求的原始 JSON 字符串
  final Completer<Map<String, dynamic>> completer;

  InterceptTask(this.requestId, this.jsonData, this.completer);
}