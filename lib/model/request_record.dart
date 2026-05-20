/// 拦截状态枚举
enum InterceptState {
  notIntercepted,    // 未拦截（拦截功能关闭时的请求）
  interceptedPending, // 拦截未处理（在队列中等待放行）
  interceptedProcessed // 拦截已处理（已放行）
}

/// 请求记录模型
class RequestRecord {
  final String id;
  final String requestId;
  final Map<String, dynamic> originalData;
  final DateTime timestamp;
  
  InterceptState state;
  Map<String, dynamic>? modifiedData; // 修改后的数据（如果已编辑）
  
  RequestRecord({
    required this.id,
    required this.requestId,
    required this.originalData,
    required this.timestamp,
    this.state = InterceptState.notIntercepted,
    this.modifiedData,
  });
  
  /// 获取显示用的 JSON 数据
  Map<String, dynamic> get displayData {
    return modifiedData ?? originalData;
  }
  
  /// 创建副本
  RequestRecord copyWith({
    String? id,
    String? requestId,
    Map<String, dynamic>? originalData,
    DateTime? timestamp,
    InterceptState? state,
    Map<String, dynamic>? modifiedData,
  }) {
    return RequestRecord(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      originalData: originalData ?? this.originalData,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      modifiedData: modifiedData ?? this.modifiedData,
    );
  }
}
