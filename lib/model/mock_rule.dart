import 'dart:convert';
import 'package:remote_interceptor/model/request_record.dart';

class MockRule {
  final String id;
  final String url;
  final HttpMethod method;
  final String mockData;
  final bool enabled;
  // 命中次数
  final int hitCount;

  MockRule({
    required this.id,
    required this.url,
    required this.method,
    required this.mockData,
    required this.enabled,
    this.hitCount = 0
  });

  factory MockRule.fromJson(Map<String, dynamic> json) {
    return MockRule(
      id: json['id'],
      url: json['url'],
      method: HttpMethod.fromString(json['method']),
      mockData: json['mockData'],
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'method': method.name,
      'mockData': mockData,
      'enabled': enabled,
    };
  }

  MockRule copyWith({
    String? id,
    String? url,
    HttpMethod? method,
    String? mockData,
    bool? enabled,
    int? hitCount,
  }) {
    return MockRule(
      id: id ?? this.id,
      url: url ?? this.url,
      method: method ?? this.method,
      mockData: mockData ?? this.mockData,
      enabled: enabled ?? this.enabled,
      hitCount: hitCount ?? this.hitCount,
    );
  }
}
