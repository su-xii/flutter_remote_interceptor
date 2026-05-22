/// 设备信息模型
class Device {
  final String serverIp;
  final int port;
  final String info;
  DateTime lastSeenTime; // 最后发现时间
  
  Device({
    required this.serverIp,
    required this.port,
    required this.info,
    DateTime? lastSeenTime,
  }) : lastSeenTime = lastSeenTime ?? DateTime.now();
  
  /// 检查设备是否在线（4秒内被发现）
  bool get isOnline {
    return DateTime.now().millisecondsSinceEpoch - 
           lastSeenTime.millisecondsSinceEpoch < 4000;
  }
  
  @override
  String toString() => '$info ($serverIp:$port)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.serverIp == serverIp;
  }
  
  @override
  int get hashCode => serverIp.hashCode;

  Device copyWith({
    String? serverIp,
    int? port,
    String? info,
    DateTime? lastSeenTime,
  }) {
    return Device(
      serverIp: serverIp ?? this.serverIp,
      port: port ?? this.port,
      info: info ?? this.info,
      lastSeenTime: lastSeenTime ?? this.lastSeenTime,
    );
  }
}
