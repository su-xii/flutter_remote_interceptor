/// 服务器状态枚举
enum ServerStatus {
  starting,
  running,
  stopped,
}

/// 客户端连接状态枚举
enum ClientConnectionStatus {
  disconnected,
  connected,
}


class ServerStatusState{
  // 客户端状态
  final ClientConnectionStatus clientConnectionStatus;
  // 服务器状态
  final ServerStatus serverStatus;

  ServerStatusState({
    required this.clientConnectionStatus,
    required this.serverStatus,
  });

  factory ServerStatusState.initial() {
    return ServerStatusState(
      clientConnectionStatus: ClientConnectionStatus.connected,
      serverStatus: ServerStatus.running,
    );
  }

  ServerStatusState copyWith({
    ClientConnectionStatus? clientConnectionStatus,
    ServerStatus? serverStatus,
  }){
    return ServerStatusState(
      clientConnectionStatus: clientConnectionStatus ?? this.clientConnectionStatus,
      serverStatus: serverStatus ?? this.serverStatus,
    );
  }
}