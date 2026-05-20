import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';

class RemoteServer {
  // 单例模式
  static final RemoteServer _instance = RemoteServer._internal();
  
  factory RemoteServer() {
    return _instance;
  }
  
  RemoteServer._internal();

  RequestHandler? requestHandler;

  DiscoveryClient? _discoveryClient;
  RemoteResponseServer? _server;
  bool _isDiscovered = false;
  bool _isStarted = false;

  Future<void> start() async{
    if (_isStarted) return; // 防止重复启动
    
    _discoveryClient = DiscoveryClient();
    _server = RemoteResponseServer();
    _server!.requestHandler = (data) async{
      if(!_isDiscovered) {
        _discoveryClient?.stop();
        _isDiscovered  = true;
      }
      if (requestHandler != null) {
        data = await requestHandler!(data);
      }
      return data;
    };
    _server!.onClientDisconnect = (){
      _isDiscovered = false;
      _discoveryClient?.start();
    };
    await _discoveryClient!.start();
    await _server?.start();
    _isStarted = true;
  }

  Future<void> dispose() async{
    if (!_isStarted) return;
    
    await _server?.stop();
    _discoveryClient?.stop();
    _isStarted = false;
  }

}