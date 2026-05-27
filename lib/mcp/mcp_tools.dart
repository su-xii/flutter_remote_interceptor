import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/mcp/models.dart' as mcp_models;
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/model/request_record.dart' as app_models;

class MCPTools {
  final Ref ref;

  MCPTools(this.ref);

  Map<String, dynamic> handleRequest(String method, Map<String, dynamic>? params) {
    switch (method) {
      case 'add_mock_rule':
        return _addMockRule(params);
      default:
        throw Exception('Method not found: $method');
    }
  }

  Map<String, dynamic> _addMockRule(Map<String, dynamic>? params) {
    if (params == null) {
      throw Exception('Params is required');
    }

    try {
      final addParams = mcp_models.AddRuleParams.fromJson(params);
      
      ref.read(mockResponseViewModelProvider.notifier).addRule(
        url: addParams.url,
        method: _convertHttpMethod(addParams.method),
        mockData: addParams.mockData,
        enabled: addParams.enabled,
        remark: addParams.remark,
      );

      return {
        'success': true,
        'message': 'Mock rule added successfully',
        'rule': addParams.toJson(),
      };
    } catch (e) {
      throw Exception('Invalid params: $e');
    }
  }

  app_models.HttpMethod _convertHttpMethod(mcp_models.HttpMethod mcpMethod) {
    switch (mcpMethod) {
      case mcp_models.HttpMethod.get:
        return app_models.HttpMethod.GET;
      case mcp_models.HttpMethod.post:
        return app_models.HttpMethod.POST;
      case mcp_models.HttpMethod.put:
        return app_models.HttpMethod.PUT;
      case mcp_models.HttpMethod.delete:
        return app_models.HttpMethod.DELETE;
      }
  }
}
