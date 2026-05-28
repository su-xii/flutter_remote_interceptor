import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/mcp/mcp_protocol.dart';
import 'package:remote_interceptor/mcp/mcp_tools.dart';

class MCPServer {
  final Ref ref;
  HttpServer? _server;
  final List<HttpResponse> _openSseClients = [];

  static const int defaultPort = 8765;

  MCPServer(this.ref);

  Future<void> start([int port = defaultPort]) async {
    if (_server != null) {
      return;
    }

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
      );

      debugPrint('MCP Server started on http://127.0.0.1:$port');

      await for (final request in _server!) {
        _handleRequest(request);
      }
    } catch (e) {
      debugPrint('Failed to start MCP Server: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    for (final response in List<HttpResponse>.from(_openSseClients)) {
      try {
        await response.close();
      } catch (_) {
        // Ignore sockets that are already closed.
      }
    }
    _openSseClients.clear();

    await _server?.close(force: true);
    _server = null;
    debugPrint('MCP Server stopped');
  }

  void _handleRequest(HttpRequest request) async {
    try {
      if (request.uri.path != '/mcp') {
        await _handleNotFound(request);
      } else if (request.method == 'GET') {
        await _handleSseStream(request);
      } else if (request.method == 'POST') {
        await _handleJsonRpcRequest(request);
      } else {
        await _handleNotFound(request);
      }
    } catch (e) {
      await _handleError(request, e);
    }
  }

  Future<void> _handleJsonRpcRequest(HttpRequest request) async {
    try {
      final body = await utf8.decodeStream(request);
      final json = jsonDecode(body) as Map<String, dynamic>;

      final rpcRequest = JsonRpcRequest.fromJson(json);

      if (rpcRequest.isNotification) {
        request.response.statusCode = HttpStatus.accepted;
        await request.response.close();
        return;
      }

      final tools = MCPTools(ref);

      dynamic result;
      try {
        result = tools.handleRequest(
          rpcRequest.method,
          rpcRequest.params as Map<String, dynamic>?,
        );
      } catch (e) {
        final response = JsonRpcResponse.error(
          error: JsonRpcError(
            code: JsonRpcError.internalError,
            message: e.toString(),
          ),
          id: rpcRequest.id,
        ).toJson();

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(response));
        await request.response.close();
        return;
      }

      final response = JsonRpcResponse.success(
        result: result,
        id: rpcRequest.id,
      ).toJson();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    } catch (e) {
      final response = JsonRpcResponse.error(
        error: JsonRpcError(
          code: JsonRpcError.parseError,
          message: 'Parse error: $e',
        ),
      ).toJson();

      request.response
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    }
  }

  Future<void> _handleSseStream(HttpRequest request) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..headers.set('Cache-Control', 'no-cache')
      ..headers.set('Connection', 'keep-alive')
      ..bufferOutput = false;

    _openSseClients.add(request.response);

    request.response.writeln(': connected');
    request.response.writeln();
    await request.response.flush();

    try {
      await request.response.done;
    } finally {
      _openSseClients.remove(request.response);
    }
  }

  Future<void> _handleNotFound(HttpRequest request) async {
    final response = JsonRpcResponse.error(
      error: JsonRpcError(
        code: JsonRpcError.methodNotFound,
        message: 'Method not found',
      ),
    ).toJson();

    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response));
    await request.response.close();
  }

  Future<void> _handleError(HttpRequest request, dynamic error) async {
    final response = JsonRpcResponse.error(
      error: JsonRpcError(
        code: JsonRpcError.internalError,
        message: 'Internal error: $error',
      ),
    ).toJson();

    request.response
      ..statusCode = HttpStatus.internalServerError
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response));
    await request.response.close();
  }
}

final mcpServerProvider = Provider<MCPServer>((ref) {
  return MCPServer(ref);
});
