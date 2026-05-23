import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';

class DeviceDiscovery {
  final DiscoveryClient _discoveryClient = DiscoveryClient();
  Function(String serverIp, int serverPort, String message)? onDeviceFound;

  DeviceDiscovery(){
    _discoveryClient.onDeviceFound = (String serverIp, int serverPort, String message) {
      onDeviceFound?.call(serverIp, serverPort, message);
    };
  }

  Future<void> start() async {
    await _discoveryClient.start();
  }

  void stop() {
    _discoveryClient.stop();
  }

  void sendConnectionRequest(String ip, int port) {
    _discoveryClient.send(ip, port, RemoteConfig.connectSignal);
  }

}
