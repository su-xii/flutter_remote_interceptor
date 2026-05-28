class JsonRpcRequest {
  final String jsonrpc = '2.0';
  final String method;
  final dynamic params;
  final dynamic id;

  JsonRpcRequest({
    required this.method,
    this.params,
    this.id,
  });

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    return JsonRpcRequest(
      method: json['method'] as String,
      params: json['params'],
      id: json['id'],
    );
  }

  bool get isNotification => id == null;
}

class JsonRpcResponse {
  final String jsonrpc = '2.0';
  final dynamic result;
  final JsonRpcError? error;
  final dynamic id;

  JsonRpcResponse.success({required this.result, this.id}) : error = null;

  JsonRpcResponse.error({required this.error, this.id}) : result = null;

  Map<String, dynamic> toJson() {
    if (error != null) {
      return {
        'jsonrpc': jsonrpc,
        'error': error!.toJson(),
        'id': id,
      };
    }
    return {
      'jsonrpc': jsonrpc,
      'result': result,
      'id': id,
    };
  }
}

class JsonRpcError {
  final int code;
  final String message;
  final dynamic data;

  JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'data': data,
    };
  }

  factory JsonRpcError.fromCode(int code, [dynamic data]) {
    switch (code) {
      case parseError:
        return JsonRpcError(code: code, message: 'Parse error', data: data);
      case invalidRequest:
        return JsonRpcError(code: code, message: 'Invalid Request', data: data);
      case methodNotFound:
        return JsonRpcError(code: code, message: 'Method not found', data: data);
      case invalidParams:
        return JsonRpcError(code: code, message: 'Invalid params', data: data);
      case internalError:
        return JsonRpcError(code: code, message: 'Internal error', data: data);
      default:
        return JsonRpcError(code: code, message: 'Unknown error', data: data);
    }
  }
}
