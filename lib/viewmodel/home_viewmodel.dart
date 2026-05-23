import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/ws_server.dart';
import 'package:remote_interceptor/state/home_state.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/router/router_util.dart';

import '../providers.dart';

class HomeViewModel extends Notifier<HomeState> {
  bool _initialized = false;

  @override
  HomeState build() {
    return HomeState.initial();
  }

  void onViewInit() {
    if (_initialized) return;
    _initialized = true;
    
    final wsServer = ref.read(gWsServerProvider);
    setRequestHandler(wsServer);
  }

  void onViewDispose() {
    disconnectClient();
  }

  void setRequestHandler(WsServer server) {
    server.requestHandler = _handleRequest;
  }

  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> requestData) async {
    state = state.copyWith(
      recordCounter: state.recordCounter + 1,
    );
    
    final String recordId = 'req_${state.recordCounter}';
    final String requestId = requestData['requestId']?.toString() ?? 'unknown';

    final record = RequestRecord(
      id: recordId,
      requestId: requestId,
      originalData: Map<String, dynamic>.from(requestData),
      timestamp: DateTime.now(),
      state: state.isIntercepting ? InterceptState.interceptedPending : InterceptState.notIntercepted,
    );

    state = state.copyWith(
      requestRecords: [...state.requestRecords, record],
    );

    if (!state.isIntercepting) {
      return requestData;
    }

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String jsonText = encoder.convert(requestData);

    final completer = Completer<Map<String, dynamic>>();
    final task = InterceptTask(recordId, jsonText, completer);

    state = state.copyWith(
      requestQueue: [...state.requestQueue, task],
    );

    if (state.requestQueue.length == 1) {
      state = state.copyWith(
        currentStatus: InterceptStatus.blocked,
        currentJsonText: jsonText,
      );
    }

    final modifiedData = await completer.future;

    final updatedRecords = state.requestRecords.map((r) {
      if (r.id == recordId) {
        return r.copyWith(
          state: InterceptState.interceptedProcessed,
          modifiedData: modifiedData,
        );
      }
      return r;
    }).toList();

    state = state.copyWith(
      requestRecords: updatedRecords,
    );

    return modifiedData;
  }

  void handleSave() {
    if (state.requestQueue.isEmpty) return;

    try {
      Map<String, dynamic> modifiedData = json.decode(state.currentJsonText) as Map<String, dynamic>;

      final firstTask = state.requestQueue.first;
      firstTask.completer.complete(modifiedData);

      final newQueue = List<InterceptTask>.from(state.requestQueue)..removeAt(0);

      if (newQueue.isNotEmpty) {
        state = state.copyWith(
          requestQueue: newQueue,
          currentStatus: InterceptStatus.blocked,
          currentJsonText: newQueue.first.jsonData,
        );
      } else {
        state = state.copyWith(
          requestQueue: [],
          currentStatus: InterceptStatus.waiting,
          currentJsonText: '',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void toggleIntercepting(bool value) {
    state = state.copyWith(isIntercepting: value);
  }

  void disconnectClient() {
    final wsServer = ref.read(gWsServerProvider);
    wsServer.disconnectClient();
  }

  void navigateToDeviceDiscovery() {
    RouterUtil.goToDeviceDiscovery();
  }

  void updateJsonText(String text) {
    state = state.copyWith(currentJsonText: text);
  }

  void releaseRequestById(String recordId, Map<String, dynamic> modifiedData) {
    final queueIndex = state.requestQueue.indexWhere((task) => task.requestId == recordId);
    
    if (queueIndex != -1) {
      final task = state.requestQueue[queueIndex];
      task.completer.complete(modifiedData);
      
      final newQueue = List<InterceptTask>.from(state.requestQueue)..removeAt(queueIndex);
      
      final updatedRecords = state.requestRecords.map((r) {
        if (r.id == recordId) {
          return r.copyWith(
            state: InterceptState.interceptedProcessed,
            modifiedData: modifiedData,
          );
        }
        return r;
      }).toList();
      
      if (newQueue.isNotEmpty) {
        state = state.copyWith(
          requestQueue: newQueue,
          requestRecords: updatedRecords,
          currentStatus: InterceptStatus.blocked,
          currentJsonText: newQueue.first.jsonData,
        );
      } else {
        state = state.copyWith(
          requestQueue: [],
          requestRecords: updatedRecords,
          currentStatus: InterceptStatus.waiting,
          currentJsonText: '',
        );
      }
    }
  }
}
