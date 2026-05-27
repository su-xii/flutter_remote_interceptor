enum HttpMethod {
  get,
  post,
  put,
  delete;

  static HttpMethod fromString(String value) {
    return HttpMethod.values.firstWhere(
      (element) => element.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HttpMethod.get,
    );
  }
}

class AddRuleParams {
  final String url;
  final HttpMethod method;
  final String mockData;
  final bool enabled;
  final String? remark;

  AddRuleParams({
    required this.url,
    required this.method,
    required this.mockData,
    required this.enabled,
    this.remark,
  });

  factory AddRuleParams.fromJson(Map<String, dynamic> json) {
    return AddRuleParams(
      url: json['url'] as String,
      method: HttpMethod.fromString(json['method'] as String),
      mockData: json['mockData'] as String,
      enabled: json['enabled'] as bool,
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'method': method.name.toUpperCase(),
      'mockData': mockData,
      'enabled': enabled,
      'remark': remark,
    };
  }
}
