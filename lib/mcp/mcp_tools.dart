import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/mcp/models.dart' as mcp_models;
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/model/request_record.dart' as app_models;

class MCPTools {
  final Ref ref;

  MCPTools(this.ref);

  dynamic handleRequest(String method, Map<String, dynamic>? params) {
    switch (method) {
      case 'initialize':
        return _initialize(params);
      case 'tools/list':
        return _listTools(params);
      case 'tools/call':
        return _callTool(params);
      default:
        throw Exception('Method not found: $method');
    }
  }

  Map<String, dynamic> _initialize(Map<String, dynamic>? params) {
    final requestedVersion = params?['protocolVersion'];
    final protocolVersion = requestedVersion is String && requestedVersion.isNotEmpty
        ? requestedVersion
        : '2025-11-05';

    return {
      'protocolVersion': protocolVersion,
      'capabilities': {
        'tools': {},
      },
      'serverInfo': {
        'name': 'flutter-mock-interceptor',
        'version': '1.0.0',
      },
      'instructions': 'Use the add_mock_rule tool to create a mock response rule in the Flutter app.',
    };
  }

  Map<String, dynamic> _listTools(Map<String, dynamic>? params) {
    return {
      'tools': [
        {
          'name': 'add_mock_rule',
          'description': '添加一个新的 Mock 规则到 Flutter Remote Interceptor 应用',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'url': {
                'type': 'string',
                'description': '拦截的 URL 路径',
              },
              'method': {
                'type': 'string',
                'enum': ['GET', 'POST', 'PUT', 'DELETE'],
                'description': 'HTTP 方法',
              },
              'mockData': {
                'type': 'string',
                'description': 'JSON 格式的 Mock 响应数据',
              },
              'enabled': {
                'type': 'boolean',
                'description': '是否启用该规则',
                'default': true,
              },
              'remark': {
                'type': 'string',
                'description': '备注说明（可选）',
              },
            },
            'required': ['url', 'method', 'mockData'],
          },
        },
      ],
    };
  }

  Map<String, dynamic> _callTool(Map<String, dynamic>? params) {
    if (params == null) {
      throw Exception('Params is required');
    }

    final toolName = params['name'] as String?;
    final toolArgs = params['arguments'] as Map<String, dynamic>?;

    if (toolName == null) {
      throw Exception('Tool name is required');
    }

    switch (toolName) {
      case 'add_mock_rule':
        return _addMockRule(toolArgs);
      default:
        throw Exception('Unknown tool: $toolName');
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
        'content': [
          {
            'type': 'text',
            'text': 'Mock 规则添加成功！\nURL: ${addParams.url}\n方法: ${addParams.method.name.toUpperCase()}\n备注: ${addParams.remark ?? "无"}',
          }
        ],
      };
    } catch (e) {
      throw Exception('Invalid params: $e');
    }
  }

  app_models.HttpMethod _convertHttpMethod(mcp_models.HttpMethod mcpMethod) {
    if (mcpMethod == mcp_models.HttpMethod.get) {
      return app_models.HttpMethod.GET;
    } else if (mcpMethod == mcp_models.HttpMethod.post) {
      return app_models.HttpMethod.POST;
    } else if (mcpMethod == mcp_models.HttpMethod.put) {
      return app_models.HttpMethod.PUT;
    } else {
      return app_models.HttpMethod.DELETE;
    }
  }
}
