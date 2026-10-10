import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/mcp/models.dart' as mcp_models;
import 'package:remote_interceptor/model/mock_page.dart';
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
      'instructions': 'Use add_mock_rule to create a global mock rule. '
          'Use list_mock_pages / jump_mock_page / get_page_mock_data / get_current_page '
          'to inspect and control page-level mock pages.',
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
        {
          'name': 'list_mock_pages',
          'description': '列出所有可跳转的 Mock 页面（页面级 Mock 的配置单元）',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'keyword': {
                'type': 'string',
                'description': '按页面名称或路由模糊过滤（可选）',
              },
              'group': {
                'type': 'string',
                'description': '按分组过滤（可选）',
              },
            },
          },
        },
        {
          'name': 'jump_mock_page',
          'description': '向被调试端下发跳转指令，使其跳转到指定 Mock 页面',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'pageId': {
                'type': 'string',
                'description': '页面标识（与 route 至少提供一个）',
              },
              'route': {
                'type': 'string',
                'description': '路由名（与 pageId 至少提供一个）',
              },
              'apply': {
                'type': 'boolean',
                'description': '是否同时应用该页面的 Mock 规则（等价于「应用规则」按钮），默认 false',
                'default': false,
              },
            },
          },
        },
        {
          'name': 'get_page_mock_data',
          'description': '获取某个页面关联的接口及其 Mock 数据',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'pageId': {
                'type': 'string',
                'description': '页面标识，缺省为当前页面',
              },
              'method': {
                'type': 'string',
                'description': '按 HTTP 方法过滤（可选）',
              },
              'path': {
                'type': 'string',
                'description': '按接口路径模糊过滤（可选）',
              },
            },
          },
        },
        {
          'name': 'get_current_page',
          'description': '获取当前生效的 Mock 页面及其最近一次跳转指令状态',
          'inputSchema': {
            'type': 'object',
            'properties': {},
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
      case 'list_mock_pages':
        return _listMockPages(toolArgs);
      case 'jump_mock_page':
        return _jumpMockPage(toolArgs);
      case 'get_page_mock_data':
        return _getPageMockData(toolArgs);
      case 'get_current_page':
        return _getCurrentPage(toolArgs);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  /// 统一封装 MCP 文本结果
  Map<String, dynamic> _textResult(String text) {
    return {
      'content': [
        {'type': 'text', 'text': text}
      ],
    };
  }

  /// 列出 Mock 页面（可按关键字 / 分组过滤）
  Map<String, dynamic> _listMockPages(Map<String, dynamic>? params) {
    final state = ref.read(mockPageViewModelProvider);
    final keyword = params?['keyword']?.toString().toLowerCase() ?? '';
    final group = params?['group']?.toString();

    final pages = state.pages.where((page) {
      if (group != null && group.isNotEmpty && page.group != group) {
        return false;
      }
      if (keyword.isEmpty) return true;
      return page.name.toLowerCase().contains(keyword) ||
          page.route.toLowerCase().contains(keyword);
    }).toList();

    return _textResult(jsonEncode({
      'total': pages.length,
      'currentPageId': state.currentPageId,
      'pages': pages
          .map((page) => {
                'id': page.id,
                'name': page.name,
                'route': page.route,
                'group': page.group,
                'paramsCount': page.routeParams.length,
                'apiCount': page.apis.length,
              })
          .toList(),
    }));
  }

  /// 下发跳转指令（同时把桌面端当前页面切到目标页面）
  Map<String, dynamic> _jumpMockPage(Map<String, dynamic>? params) {
    if (params == null) throw Exception('Params is required');

    final pageId = params['pageId']?.toString();
    final route = params['route']?.toString();
    if ((pageId == null || pageId.isEmpty) && (route == null || route.isEmpty)) {
      throw Exception('pageId 与 route 至少提供一个');
    }

    final notifier = ref.read(mockPageViewModelProvider.notifier);
    final state = ref.read(mockPageViewModelProvider);

    // 路由允许重复，因此优先按唯一的 pageId 精确匹配，其次再按 route 取第一个
    MockPageConfig? target;
    if (pageId != null && pageId.isNotEmpty) {
      for (final page in state.pages) {
        if (page.id == pageId) {
          target = page;
          break;
        }
      }
    }
    if (target == null && route != null && route.isNotEmpty) {
      for (final page in state.pages) {
        if (page.route == route) {
          target = page;
          break;
        }
      }
    }

    if (target == null) {
      return _textResult(jsonEncode({
        'success': false,
        'message': '未找到匹配的 Mock 页面',
      }));
    }

    // 同步 UI 详情页并下发跳转指令（指令结果通过 commandResult 异步回执）
    notifier.openPage(target.id);
    notifier.jumpToPage(target);

    // 可选：同时让该页面的 Mock 规则生效
    final apply = params['apply'] == true;
    if (apply) {
      notifier.applyPage(target);
    }

    return _textResult(jsonEncode({
      'success': true,
      'message': apply ? '跳转指令已下发，并已应用该页面规则' : '跳转指令已下发',
      'pageId': target.id,
      'page': target.route,
      'applied': apply,
    }));
  }

  /// 获取页面关联接口及其 Mock 数据
  Map<String, dynamic> _getPageMockData(Map<String, dynamic>? params) {
    final state = ref.read(mockPageViewModelProvider);
    final pageId = params?['pageId']?.toString() ?? state.currentPageId;
    final method = params?['method']?.toString().toUpperCase();
    final path = params?['path']?.toString();

    MockPageConfig? page;
    for (final item in state.pages) {
      if (item.id == pageId) {
        page = item;
        break;
      }
    }
    if (page == null) {
      return _textResult(jsonEncode({
        'success': false,
        'message': '未找到页面: ${pageId ?? '未指定且当前无生效页面'}',
      }));
    }

    final apis = page.apis.where((api) {
      if (method != null && method.isNotEmpty) {
        if (api.method.name.toUpperCase() != method) return false;
      }
      if (path != null && path.isNotEmpty && !api.path.contains(path)) {
        return false;
      }
      return true;
    }).toList();

    return _textResult(jsonEncode({
      'success': true,
      'pageId': page.id,
      'page': page.route,
      'name': page.name,
      'routeParams': page.routeParams,
      'apis': apis
          .map((api) => {
                'method': api.method.name.toUpperCase(),
                'path': api.path,
                'response': api.response,
                'remark': api.remark,
                'enabled': api.enabled,
              })
          .toList(),
    }));
  }

  /// 获取当前生效页面与最近一次跳转指令状态
  Map<String, dynamic> _getCurrentPage(Map<String, dynamic>? params) {
    final state = ref.read(mockPageViewModelProvider);
    final page = state.currentPage;

    return _textResult(jsonEncode({
      'success': true,
      'pageId': page?.id,
      'page': page?.route,
      'name': page?.name,
      'jumpStatus': state.jumpResult.status.name,
      'jumpMessage': state.jumpResult.message,
    }));
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
        requestParam: addParams.requestParam,
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
