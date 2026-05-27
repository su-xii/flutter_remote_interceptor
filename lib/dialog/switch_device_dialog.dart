import 'package:flutter/material.dart';

import '../page/device_discovery_page.dart'; // 确保导入你的状态或 ViewModel

class SwitchDeviceDialog extends StatelessWidget {
  final VoidCallback onSwitchConfirmed;

  const SwitchDeviceDialog({
    super.key,
    required this.onSwitchConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 中间的大圆圈图标容器
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWarningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.swap_horiz,
                size: 40,
                color: kWarningColor,
              ),
            ),
            const SizedBox(height: 20),
            // 标题
            const Text(
              '切换设备',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // 描述文字
            Text(
              '确定要断开当前连接并选择其他设备吗？',
              style: TextStyle(
                fontSize: 14,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // 按钮行
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
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
                // 确定按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 先关闭弹窗
                      onSwitchConfirmed(); // 执行外部传入的业务逻辑
                    },
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
                      '确定',
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
}