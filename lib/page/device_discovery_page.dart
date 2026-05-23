import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../model/device.dart';
import '../state/device_discovery_state.dart';
import '../viewmodel/device_discovery_viewmodel.dart';

const Color kPrimaryColor = Color(0xFF165DFF);
const Color kSuccessColor = Color(0xFF00B42A);
const Color kWarningColor = Color(0xFFFF7D00);
const Color kErrorColor = Color(0xFFF53F3F);
const Color kTextPrimary = Color(0xFF1D2129);
const Color kTextSecondary = Color(0xFF86909C);
const Color kBgCard = Color(0xFFFFFFFF);
const Color kBgPage = Color(0xFFF2F3F5);

class DeviceDiscoveryPage extends ConsumerStatefulWidget {
  const DeviceDiscoveryPage({super.key});

  @override
  ConsumerState<DeviceDiscoveryPage> createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends ConsumerState<DeviceDiscoveryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(gDeviceDiscoveryViewModelProvider.notifier).onViewInit();
    });
  }

  @override
  void dispose() {
    ref.read(gDeviceDiscoveryViewModelProvider.notifier).onViewDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gDeviceDiscoveryViewModelProvider);
    final devices = state.onlineDevices;
    final notifier = ref.read(gDeviceDiscoveryViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        title: const Text(
          '设备发现',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () {
                notifier.stopScanning();
                notifier.clearDevices();
                notifier.startScanning();
              },
              tooltip: '刷新扫描',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(state, devices.length),
          
          Expanded(
            child: devices.isEmpty
                ? _buildEmptyState(state)
                : _buildDeviceList(devices, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(DeviceDiscoveryState state, int deviceCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: state.isScanning 
                  ? kSuccessColor.withOpacity(0.1) 
                  : kTextSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isScanning ? Icons.wifi_tethering : Icons.wifi_off,
              color: state.isScanning ? kSuccessColor : kTextSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isScanning ? '正在扫描设备...' : '已停止扫描',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: state.isScanning ? kSuccessColor : kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '发现 $deviceCount 个在线设备',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DeviceDiscoveryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kBgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.devices_other,
              size: 64,
              color: kTextSecondary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state.isScanning ? '正在搜索设备...' : '未发现设备',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.isScanning 
                ? '请确保手机和电脑在同一网络' 
                : '等待扫描设备...',
            style: const TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<Device> devices, DeviceDiscoveryState state, DeviceDiscoveryViewModel notifier) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(context, state, device, notifier);
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceDiscoveryState state, Device device, DeviceDiscoveryViewModel notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: state.isConnecting
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => _buildConnectDialog(context, device),
                  );

                  if (confirmed == true) {
                    notifier.connectToDevice(device);
                    
                    notifier.onConnectionSuccess = () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已连接到 ${device.info}'),
                            backgroundColor: kSuccessColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                        
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) {
                            notifier.navigateToHome();
                          }
                        });
                      }
                    };
                  }
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone_iphone,
                    color: kPrimaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.info,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${device.serverIp}:${device.port}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: device.isOnline ? kSuccessColor : kTextSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.isOnline ? '在线' : '离线',
                            style: TextStyle(
                              fontSize: 12,
                              color: device.isOnline ? kSuccessColor : kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: kTextSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(device.lastSeenTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: kTextSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: kTextSecondary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectDialog(BuildContext context, Device device) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phonelink_setup,
                size: 40,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '连接设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '是否连接到设备？',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kBgPage,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    device.info,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${device.serverIp}:${device.port}',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '连接',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
