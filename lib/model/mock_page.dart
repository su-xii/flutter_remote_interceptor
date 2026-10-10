import 'package:remote_interceptor/model/request_record.dart';

/// 单个接口的 Mock 配置（页面级 Mock 的接口粒度配置）
class MockApiConfig {
  /// HTTP 方法
  final HttpMethod method;

  /// 接口路径。
  ///
  /// 支持两种配置写法：完整 URL（`https://api.x.com/api/user/profile`）或纯路径
  /// （`/api/user/profile`），命中判定时会去掉 query / fragment 后比对（见
  /// `MockPageViewModel._matchPath`）。
  final String path;

  /// Mock 响应体（JSON 字符串）
  final String response;

  /// 备注（可选）
  final String? remark;

  /// 是否启用。
  ///
  /// 同一页面下允许存在多个配置，但「方法 + 路径」相同的配置**互斥**，同时只生效一个。
  final bool enabled;

  /// 命中次数（仅内存态，不持久化，与全局 Mock 规则保持一致）
  final int hitCount;

  const MockApiConfig({
    required this.method,
    required this.path,
    required this.response,
    this.remark,
    this.enabled = true,
    this.hitCount = 0,
  });

  /// 从 JSON 构造；方法名解析失败时兜底为 GET，避免脏数据导致整个配置加载失败
  factory MockApiConfig.fromJson(Map<String, dynamic> json) {
    HttpMethod method;
    try {
      method = HttpMethod.fromString(json['method']?.toString() ?? 'GET');
    } catch (_) {
      method = HttpMethod.GET;
    }
    return MockApiConfig(
      method: method,
      path: json['path']?.toString() ?? '',
      response: json['response']?.toString() ?? '{}',
      remark: json['remark']?.toString(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.name.toUpperCase(),
      'path': path,
      'response': response,
      'remark': remark,
      'enabled': enabled,
    };
  }

  MockApiConfig copyWith({
    HttpMethod? method,
    String? path,
    String? response,
    String? remark,
    bool clearRemark = false,
    bool? enabled,
    int? hitCount,
  }) {
    return MockApiConfig(
      method: method ?? this.method,
      path: path ?? this.path,
      response: response ?? this.response,
      remark: clearRemark ? null : (remark ?? this.remark),
      enabled: enabled ?? this.enabled,
      hitCount: hitCount ?? this.hitCount,
    );
  }
}

/// 页面级 Mock 的配置单元：一个路由 + 预设路由入参 + 一组关联接口
class MockPageConfig {
  /// 页面唯一标识（pageId）
  final String id;

  /// 页面名称，如「用户详情」
  final String name;

  /// 路由地址 / 路由名，如 `/user/detail`。
  /// 下发跳转指令时作为 `payload.page`，即宿主 `RouteUtils.toNamed(page, {arguments})` 的首参。
  final String route;

  /// 所属分组 / 模块（可选，用于列表筛选）
  final String? group;

  /// 首字图标配色索引（对齐原型 `colorIndex`）
  final int colorIndex;

  /// 首字图标字符（可选，缺省取名称首字）
  final String? iconChar;

  /// 预设路由入参（展示用，同时作为跳转指令的 `arguments`）
  final Map<String, dynamic> routeParams;

  /// 关联接口及其 Mock 数据
  final List<MockApiConfig> apis;

  const MockPageConfig({
    required this.id,
    required this.name,
    required this.route,
    this.group,
    this.colorIndex = 0,
    this.iconChar,
    this.routeParams = const <String, dynamic>{},
    this.apis = const <MockApiConfig>[],
  });

  /// 列表 / 详情展示用的首字图标字符：优先使用显式配置，否则取名称首字
  String get displayIconChar {
    if (iconChar != null && iconChar!.isNotEmpty) return iconChar!;
    if (name.isEmpty) return '?';
    return name.trim().firstCharacter;
  }

  factory MockPageConfig.fromJson(Map<String, dynamic> json) {
    return MockPageConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      group: json['group']?.toString(),
      colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      iconChar: json['iconChar']?.toString(),
      routeParams: (json['routeParams'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      apis: (json['apis'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MockApiConfig.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route': route,
      'group': group,
      'colorIndex': colorIndex,
      'iconChar': iconChar,
      'routeParams': routeParams,
      'apis': apis.map((e) => e.toJson()).toList(),
    };
  }

  MockPageConfig copyWith({
    String? id,
    String? name,
    String? route,
    String? group,
    int? colorIndex,
    String? iconChar,
    Map<String, dynamic>? routeParams,
    List<MockApiConfig>? apis,
  }) {
    return MockPageConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      route: route ?? this.route,
      group: group ?? this.group,
      colorIndex: colorIndex ?? this.colorIndex,
      iconChar: iconChar ?? this.iconChar,
      routeParams: routeParams ?? this.routeParams,
      apis: apis ?? this.apis,
    );
  }
}

/// 取字符串首字符（按 rune 安全截取，兼容中文与 emoji，避免截断多字节字符）
extension on String {
  /// 返回首个字符
  String get firstCharacter {
    final runes = this.runes;
    if (runes.isEmpty) return '?';
    return String.fromCharCode(runes.first);
  }
}
