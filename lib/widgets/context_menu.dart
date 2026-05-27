import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';

/// 菜单项模型
class ContextMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool? isDestructive;

  ContextMenuItem({
    required this.label,
    this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// 通用右键菜单组件
class ContextMenu extends ConsumerStatefulWidget {
  final Widget child;
  final List<ContextMenuItem> Function() getMenuItems;

  const ContextMenu({
    super.key,
    required this.child,
    required this.getMenuItems,
  });

  @override
  ConsumerState<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends ConsumerState<ContextMenu> {
  OverlayEntry? _overlayEntry;

  void _showMenu(BuildContext context, Offset position) {
    _hideMenu();
    final colors = ref.read(themeProvider);

    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    
    // 估算菜单尺寸
    const menuMinWidth = 160.0;
    const menuItemHeight = 48.0; // 估算的每项高度
    final menuItems = widget.getMenuItems();
    final estimatedMenuHeight = menuItems.length * menuItemHeight;
    
    // 计算位置，处理边界情况
    double left = position.dx;
    double top = position.dy;
    
    // 检查右侧空间是否足够
    if (left + menuMinWidth > screenSize.width) {
      left = position.dx - menuMinWidth;
    }
    
    // 检查下方空间是否足够
    if (top + estimatedMenuHeight > screenSize.height) {
      top = position.dy - estimatedMenuHeight;
    }
    
    // 确保菜单不会超出屏幕左侧或顶部
    left = left.clamp(0.0, screenSize.width - menuMinWidth);
    top = top.clamp(0.0, screenSize.height - estimatedMenuHeight);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        if (menuItems.isEmpty) return const SizedBox.shrink();

        return Stack(
          children: [
            GestureDetector(
              onTap: _hideMenu,
              onPanStart: (_) => _hideMenu(),
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: colors.bgCard,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: menuMinWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: menuItems
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isLast = index == menuItems.length - 1;
                          return InkWell(
                            onTap: () {
                              _hideMenu();
                              item.onTap();
                            },
                            borderRadius: BorderRadius.vertical(
                              top: index == 0 ? const Radius.circular(8) : Radius.zero,
                              bottom: isLast ? const Radius.circular(8) : Radius.zero,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  if (item.icon != null) ...[
                                    Icon(
                                      item.icon,
                                      size: 18,
                                      color: item.isDestructive ?? false
                                          ? colors.error
                                          : colors.textPrimary,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: item.isDestructive ?? false
                                          ? colors.error
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showMenu(context, details.globalPosition);
      },
      child: widget.child,
    );
  }
}
