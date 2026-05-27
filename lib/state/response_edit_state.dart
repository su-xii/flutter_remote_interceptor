import 'dart:async';
import '../model/request_record.dart';

/// 拦截状态枚举
enum InterceptStatus {
  waiting,    // 等待拦截请求
  blocked,    // 已拦截正在处理
  released,   // 已放行
}

/// 拦截任务类
class InterceptTask {
  final String requestId;
  final String jsonData;
  final Completer<Map<String, dynamic>> completer;

  InterceptTask(this.requestId, this.jsonData, this.completer);
}

/// 首页状态类
class ResponseEditState {
  final bool isIntercepting;
  final List<RequestRecord> requestRecords;
  final List<InterceptTask> requestQueue;
  final InterceptStatus currentStatus;
  final String currentJsonText;
  final int recordCounter;

  ResponseEditState({
    required this.isIntercepting,
    required this.requestRecords,
    required this.requestQueue,
    required this.currentStatus,
    required this.currentJsonText,
    required this.recordCounter,
  });

  /// 初始状态
  factory ResponseEditState.initial() {
    return ResponseEditState(
      isIntercepting: false,
      requestRecords: [],
      requestQueue: [],
      currentStatus: InterceptStatus.waiting,
      currentJsonText: '',
      recordCounter: 0,
    );
  }

  /// 创建副本
  ResponseEditState copyWith({
    bool? isIntercepting,
    List<RequestRecord>? requestRecords,
    List<InterceptTask>? requestQueue,
    InterceptStatus? currentStatus,
    String? currentJsonText,
    int? recordCounter,
  }) {
    return ResponseEditState(
      isIntercepting: isIntercepting ?? this.isIntercepting,
      requestRecords: requestRecords ?? this.requestRecords,
      requestQueue: requestQueue ?? this.requestQueue,
      currentStatus: currentStatus ?? this.currentStatus,
      currentJsonText: currentJsonText ?? this.currentJsonText,
      recordCounter: recordCounter ?? this.recordCounter,
    );
  }
}
