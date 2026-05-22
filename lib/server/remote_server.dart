import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import 'package:remote_interceptor/state/server_state.dart';

class RemoteServer {
  RemoteServer();

  RequestHandler? requestHandler;

  DiscoveryClient? _discoveryClient;
  RemoteResponseServer? _server;
  bool _isDiscovered = false;
  bool _isStarted = false;
  
  // 设备发现回调
  Function(String serverIp, int serverPort, String message)? onDeviceFound;
  
  // 服务器状态
  ServerStatus _status = ServerStatus.stopped;
  ServerStatus get status => _status;
  
  // 客户端连接状态
  ClientConnectionStatus _clientStatus = ClientConnectionStatus.disconnected;
  ClientConnectionStatus get clientStatus => _clientStatus;
  
  // 状态变化回调
  Function(ServerStatus)? onStatusChanged;
  Function(ClientConnectionStatus)? onClientStatusChanged;
  
  void _updateStatus(ServerStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }
  
  void _updateClientStatus(ClientConnectionStatus newStatus) {
    _clientStatus = newStatus;
    onClientStatusChanged?.call(newStatus);
  }

  Future<void> start() async{
    if (_isStarted) return; // 防止重复启动
    
    try {
      _updateStatus(ServerStatus.starting);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      
      _discoveryClient = DiscoveryClient();
      _discoveryClient!.onDeviceFound = (String serverIp, int serverPort, String message) {
        onDeviceFound?.call(serverIp, serverPort, message);
      };
      _server = RemoteResponseServer();
      _server!.requestHandler = (data) async{
        if (requestHandler != null) {
          data = await requestHandler!(data);
        }
        return data;
      };
      _server!.onClientDisconnect = (){
        _isDiscovered = false;
        _updateClientStatus(ClientConnectionStatus.disconnected);
        _discoveryClient?.start();
      };
      _server!.onClientConnect = (){
        if(!_isDiscovered) {
          _discoveryClient?.stop();
          _isDiscovered  = true;
          _updateStatus(ServerStatus.running);
          _updateClientStatus(ClientConnectionStatus.connected);
        }
      };
      
      await _discoveryClient!.start();
      await _server?.start();
      _isStarted = true;
      _updateStatus(ServerStatus.running);
    } catch (e) {
      _updateStatus(ServerStatus.stopped);
      _updateClientStatus(ClientConnectionStatus.disconnected);
      rethrow;
    }
  }

  Future<void> stop() async{
    if (!_isStarted) return;
    
    await _server?.stop();
    _discoveryClient?.stop();
    _isStarted = false;
    _updateStatus(ServerStatus.stopped);
    _updateClientStatus(ClientConnectionStatus.disconnected);
  }

  /// 启动设备发现
  void startDeviceDiscovery() {
    _discoveryClient?.start();
  }

  /// 停止设备发现
  void stopDeviceDiscovery() {
    _discoveryClient?.stop();
  }

  /// 连接到指定设备
  void connectToDevice(String ip, int port) {
    _discoveryClient?.send(ip, port, RemoteConfig.connectSignal);
  }

}
