import 'package:flutter/material.dart';
import 'package:remote_interceptor/model/request_record.dart';

/// HTTP 方法对应的展示颜色（全局 Mock 列表与页面级 Mock 统一使用）
Color apiMethodColor(HttpMethod method) {
  switch (method) {
    case HttpMethod.GET:
      return const Color(0xFF3B82F6); // 蓝色
    case HttpMethod.POST:
      return const Color(0xFF10B981); // 绿色
    case HttpMethod.PUT:
      return const Color(0xFFF59E0B); // 黄色
    case HttpMethod.DELETE:
      return const Color(0xFFEF4444); // 红色
    case HttpMethod.PATCH:
      return const Color(0xFF8B5CF6); // 紫色
    default:
      return const Color(0xFF86909C); // 灰色
  }
}

/// HTTP 方法徽标
class ApiMethodBadge extends StatelessWidget {
  final HttpMethod method;

  /// 字号
  final double fontSize;

  const ApiMethodBadge({
    super.key,
    required this.method,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final color = apiMethodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        method.name.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
