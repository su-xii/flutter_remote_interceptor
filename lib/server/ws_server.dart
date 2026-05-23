import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import '../state/server_state.dart';

class WsServer {
  RemoteResponseServer? _server;
  RequestHandler? requestHandler;
  ServerStatus _status = ServerStatus.stopped;
  ServerStatus get status => _status;
  
  ClientConnectionStatus _clientStatus = ClientConnectionStatus.disconnected;
  ClientConnectionStatus get clientStatus => _clientStatus;
  
  Function(ServerStatus)? onStatusChanged;
  Function(ClientConnectionStatus)? onClientStatusChanged;

  WsServer();

  void _updateStatus(ServerStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }
  
  void _updateClientStatus(ClientConnectionStatus newStatus) {
    _clientStatus = newStatus;
    onClientStatusChanged?.call(newStatus);
  }

  Future<void> start() async {
    if (_server != null) return;
    
    try {
      _updateStatus(ServerStatus.starting);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      
      _server = RemoteResponseServer();
      _server!.requestHandler = (data) async {
        if (requestHandler != null) {
          data = await requestHandler!(data);
        }
        return data;
      };
      
      _server!.onClientDisconnect = () {
        _updateClientStatus(ClientConnectionStatus.disconnected);
      };
      
      _server!.onClientConnect = () {
        _updateStatus(ServerStatus.running);
        _updateClientStatus(ClientConnectionStatus.connected);
      };
      
      await _server!.start();
      _updateStatus(ServerStatus.running);
    } catch (e) {
      _updateStatus(ServerStatus.stopped);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      rethrow;
    }
  }

  void disconnectClient() => _server?.disconnectClient();

  Future<void> stop() async {
    if (_server == null) return;
    
    await _server!.stop();
    _server = null;
    _updateStatus(ServerStatus.stopped);
    _updateClientStatus(ClientConnectionStatus.disconnected);
  }

  bool get isConnected => _clientStatus == ClientConnectionStatus.connected;
}
