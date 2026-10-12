import 'package:flutter/material.dart';

/// 页面级 Mock 的首字图标配色盘（对齐需求原型）
const List<Color> kPageIconPalette = [
  Color(0xFF2D6DF6),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF3B82F6),
];

/// 按配色索引取首字图标背景色（索引越界时循环取色）
Color pageIconColor(int colorIndex) {
  if (colorIndex < 0) return kPageIconPalette.first;
  return kPageIconPalette[colorIndex % kPageIconPalette.length];
}

/// 页面首字图标（页面列表、详情页、选择弹窗共用）
class PageIconAvatar extends StatelessWidget {
  /// 展示字符，通常为页面名首字
  final String char;

  /// 配色索引
  final int colorIndex;

  /// 边长
  final double size;

  const PageIconAvatar({
    super.key,
    required this.char,
    required this.colorIndex,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = pageIconColor(colorIndex);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Text(
        char,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
