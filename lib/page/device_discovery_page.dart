import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../viewmodel/device_discovery_viewmodel.dart';
import '../model/device.dart';
import 'home_page.dart';

class DeviceDiscoveryPage extends ConsumerStatefulWidget {
  const DeviceDiscoveryPage({super.key});

  @override
  ConsumerState<DeviceDiscoveryPage> createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends ConsumerState<DeviceDiscoveryPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动开始扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceDiscoveryViewModelProvider).startScanning();
    });
  }

  @override
  void dispose() {
    // 页面销毁时停止扫描
    ref.read(deviceDiscoveryViewModelProvider).stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(deviceDiscoveryViewModelProvider);
    final devices = viewModel.onlineDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备发现'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 重新扫描
              viewModel.stopScanning();
              viewModel.clearDevices();
              viewModel.startScanning();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 扫描状态提示
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Icon(
                  viewModel.isScanning ? Icons.wifi_tethering : Icons.wifi_off,
                  color: viewModel.isScanning ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.isScanning ? '正在扫描设备...' : '已停止扫描',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: viewModel.isScanning ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '发现 ${devices.length} 个在线设备',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 扫描开关
                Switch(
                  value: viewModel.isScanning,
                  onChanged: (value) {
                    if (value) {
                      viewModel.startScanning();
                    } else {
                      viewModel.stopScanning();
                    }
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          
          // 设备列表
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          viewModel.isScanning ? '正在搜索设备...' : '未发现设备',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.isScanning 
                              ? '请确保手机和电脑在同一网络' 
                              : '点击左上角开关开始扫描',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _buildDeviceCard(context, viewModel, device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceDiscoveryViewModel viewModel, Device device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // 显示连接确认对话框
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('连接设备'),
              content: Text('是否连接到设备:\n${device.info}\n(${device.serverIp}:${device.port})'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('连接'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            // 连接到设备
            viewModel.connectToDevice(device);
            
            // 延迟一下再跳转，让用户看到提示
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              // 显示成功提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已连接到 ${device.info}'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // 使用 pushReplacement 替换当前页面，确保一次服务生命周期只选择一条设备
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 设备图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // 设备信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.info,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.serverIp}:${device.port}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: device.isOnline ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.isOnline ? '在线' : '离线',
                          style: TextStyle(
                            fontSize: 12,
                            color: device.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '最后发现: ${_formatTime(device.lastSeenTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 连接箭头
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
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
