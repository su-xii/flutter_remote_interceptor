/// 「进入页面」指令的执行状态
enum JumpStatus {
  /// 空闲：尚未下发过指令
  idle,

  /// 已下发，等待手机端回执
  sending,

  /// 跳转成功
  success,

  /// 跳转失败
  failure,
}

/// 跳转指令结果（用于「进入页面」按钮的状态回显）
class JumpResult {
  /// 当前状态
  final JumpStatus status;

  /// 关联的指令 ID，用于过滤过期的回执
  final String? commandId;

  /// 失败原因 / 补充说明
  final String? message;

  const JumpResult({
    required this.status,
    this.commandId,
    this.message,
  });

  /// 空闲态常量
  static const JumpResult idle = JumpResult(status: JumpStatus.idle);

  JumpResult copyWith({
    JumpStatus? status,
    String? commandId,
    String? message,
    bool clearMessage = false,
  }) {
    return JumpResult(
      status: status ?? this.status,
      commandId: commandId ?? this.commandId,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
