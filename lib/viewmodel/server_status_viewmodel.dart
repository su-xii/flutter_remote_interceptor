import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';

import '../state/server_status_state.dart';

class ServerStatusViewModel extends StateNotifier<ServerStatusState> {
  final RemoteServer _remoteServer;
  late final StreamSubscription<void> _clientConnectSubscription;
  ServerStatusViewModel(this._remoteServer) : super(ServerStatusState(
    serverStatus: _remoteServer.serverStatus,
    clientConnectionStatus: _remoteServer.clientConnectionStatus
  )){
    _clientConnectSubscription = _remoteServer.onClientConnect.listen((_)=>_updateClientStatus(ClientConnectionStatus.connected));
    _remoteServer.onClientDisconnect = () => _updateClientStatus(ClientConnectionStatus.disconnected);
    _remoteServer.onServerRunning = () => _updateServerStatus(ServerStatus.running);
    _remoteServer.onServerStop = ()=> _updateServerStatus(ServerStatus.stopped);
  }

  @override
  void dispose() async{
    await _clientConnectSubscription.cancel();
    super.dispose();
  }

  void _updateServerStatus(ServerStatus status) {
    state = state.copyWith(serverStatus: status);
  }

  void _updateClientStatus(ClientConnectionStatus status) {
    state = state.copyWith(clientConnectionStatus: status);
  }
}
