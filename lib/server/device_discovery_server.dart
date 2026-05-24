import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import 'package:remote_interceptor/model/device_model.dart';

class DeviceDiscoveryServer {
  final DiscoveryClient _discoveryClient = DiscoveryClient();

  DeviceDiscoveryServer() {
    _discoveryClient.onDeviceFound =
        (String serverIp, int serverPort, String message) {
      onDeviceFound?.call(serverIp, serverPort, message);
    };
  }

  Function(String serverIp, int serverPort, String message)? onDeviceFound;

  Future<void> start() async {
    await _discoveryClient.start();
  }

  void stop() {
    _discoveryClient.manualDevices = null;
    _discoveryClient.stop();
  }

  void sendConnectionRequest(String ip, int port) {
    _discoveryClient.send(ip, port, RemoteConfig.connectSignal);
  }

  set manualDevices(Map<String, DeviceModel> manualDevices) {
    _discoveryClient.manualDevices = manualDevices
        .map((key, value) => MapEntry(key, (value.serverIp, value.port)));
  }
}
