import 'dart:convert';

import 'package:flutter/material.dart';

/// JSON 预览组件：格式化输出 + 轻量语法高亮。
///
/// 说明：不负责背景与边框，由调用方包一层容器（便于复用不同的卡片样式）。
/// 用于「页面级 Mock」的路由入参、接口 Mock 数据展示，视觉对齐需求原型。
class JsonPreview extends StatelessWidget {
  /// 待展示的数据，支持 Map / List / 基础类型 / JSON 字符串
  final dynamic data;

  /// 最大高度，超出后在组件内部滚动；传 `null` 表示自适应内容高度
  final double? maxHeight;

  /// 数据为空时的占位文案
  final String emptyPlaceholder;

  /// 字号
  final double fontSize;

  const JsonPreview({
    super.key,
    required this.data,
    this.maxHeight,
    this.emptyPlaceholder = '// 暂无数据',
    this.fontSize = 12,
  });

  /// 键名配色
  static const Color _keyColor = Color(0xFF2D6DF6);
  /// 字符串值配色
  static const Color _stringColor = Color(0xFF0B7E4B);
  /// 数字值配色
  static const Color _numberColor = Color(0xFFB45A00);
  /// 布尔值配色
  static const Color _booleanColor = Color(0xFFC42E2E);
  /// null 值与占位文案配色
  static const Color _nullColor = Color(0xFF8E9DB1);
  /// 普通文本配色
  static const Color _plainColor = Color(0xFF3D4E66);

  /// JSON 词法匹配：字符串（含键名）/ 布尔 / null / 数字
  static final RegExp _tokenRegex = RegExp(
    r'"(?:\\.|[^"\\])*"(\s*:)?|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+\-]?\d+)?',
  );

  @override
  Widget build(BuildContext context) {
    final text = _prettyJson(data);
    final isEmpty = text.trim().isEmpty;

    final content = Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: 1.7,
          fontFamily: 'monospace',
          color: _plainColor,
        ),
        children: isEmpty
            ? [_placeholderSpan()]
            : _highlightSpans(text),
      ),
    );

    if (maxHeight == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight!),
      child: SingleChildScrollView(child: content),
    );
  }

  /// 空数据占位
  TextSpan _placeholderSpan() {
    return TextSpan(
      text: emptyPlaceholder,
      style: const TextStyle(color: _nullColor),
    );
  }

  /// 将数据格式化为缩进 JSON；字符串会先尝试解析为 JSON，失败则原样展示
  String _prettyJson(dynamic value) {
    if (value == null) return '';
    if (value is String) {
      if (value.trim().isEmpty) return '';
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
      } catch (_) {
        return value;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  /// 按词法切分并着色，未匹配部分保持普通文本色
  List<TextSpan> _highlightSpans(String text) {
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in _tokenRegex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(color: _colorOf(match.group(0)!)),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  /// 根据词法片段判定配色
  Color _colorOf(String token) {
    if (token.startsWith('"')) {
      // 以冒号结尾的是对象的键
      return token.trimRight().endsWith(':') ? _keyColor : _stringColor;
    }
    if (token == 'true' || token == 'false') return _booleanColor;
    if (token == 'null') return _nullColor;
    return _numberColor;
  }
}
