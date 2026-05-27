import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/data/local/mock_rule_store.dart';
import 'package:remote_interceptor/model/mock_rule.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/state/mock_response_state.dart';


class MockResponseViewModel extends StateNotifier<MockResponseState> {
  final MockRuleStore _mockRuleStore;

  MockResponseViewModel(this._mockRuleStore) :super(MockResponseState.initial()) {
    _loadRules();
  }

  Future<Map<String, dynamic>> handleRequest(
      Map<String, dynamic> requestData) async {
    final String requestId = requestData['requestId']?.toString() ?? 'unknown';
    final record = RequestRecord(
        id: "mock",
        requestId: requestId,
        originalData: Map<String, dynamic>.from(requestData),
        timestamp: DateTime.now(),
        url: requestData['requestOptions']['uri'] ?? 'unknown',
        method: requestData['requestOptions']['method'] ?? 'unknown',
        statusCode: requestData['statusCode']);

    final targetIndex = state.mockRules.indexWhere(
        (e) => e.enabled && e.url == record.url && e.method == record.method);

    if (targetIndex != -1) {
      final target = state.mockRules[targetIndex];
      final newRules = state.mockRules.map((rule) {
        if (rule.id == target.id) {
          return rule.copyWith(hitCount: rule.hitCount + 1);
        }
        return rule;
      }).toList();
      state = state.copyWith(mockRules: newRules);
      requestData['data'] = target.mockData;
    }
    return requestData;
  }

  Future<void> _loadRules() async {
    final rules = await _mockRuleStore.load();
    state = state.copyWith(mockRules: rules);
  }

  Future<void> addRule({
    required String url,
    required HttpMethod method,
    required String mockData,
    required bool enabled,
  }) async {
    final newRule = MockRule(
      id: DateTime.now().toIso8601String(),
      url: url,
      method: method,
      mockData: mockData,
      enabled: enabled,
    );
    
    List<MockRule> newRules;
    if (enabled) {
      newRules = state.mockRules.map((rule) {
        if (rule.url == url && rule.method == method) {
          return rule.copyWith(enabled: false);
        }
        return rule;
      }).toList();
    } else {
      newRules = List.from(state.mockRules);
    }
    
    newRules.add(newRule);
    state = state.copyWith(mockRules: newRules);
    await _mockRuleStore.save(newRules);
  }

  Future<void> updateRule({
    required String id,
    required String url,
    required HttpMethod method,
    required String mockData,
    required bool enabled,
  }) async {
    List<MockRule> newRules;
    
    if (enabled) {
      newRules = state.mockRules.map((rule) {
        if (rule.id == id) {
          return rule.copyWith(
            url: url,
            method: method,
            mockData: mockData,
            enabled: enabled,
          );
        }
        if (rule.url == url && rule.method == method) {
          return rule.copyWith(enabled: false);
        }
        return rule;
      }).toList();
    } else {
      newRules = state.mockRules.map((rule) {
        if (rule.id == id) {
          return rule.copyWith(
            url: url,
            method: method,
            mockData: mockData,
            enabled: enabled,
          );
        }
        return rule;
      }).toList();
    }
    
    state = state.copyWith(mockRules: newRules);
    await _mockRuleStore.save(newRules);
  }

  Future<void> deleteRule(String id) async {
    final newRules = state.mockRules.where((rule) => rule.id != id).toList();
    state = state.copyWith(mockRules: newRules);
    await _mockRuleStore.save(newRules);
  }

  Future<void> toggleRule(String id) async {
    final targetRule = state.mockRules.firstWhere((rule) => rule.id == id);
    final willBeEnabled = !targetRule.enabled;
    
    List<MockRule> newRules;
    
    if (willBeEnabled) {
      newRules = state.mockRules.map((rule) {
        if (rule.id == id) {
          return rule.copyWith(enabled: true);
        }
        if (rule.url == targetRule.url && rule.method == targetRule.method) {
          return rule.copyWith(enabled: false);
        }
        return rule;
      }).toList();
    } else {
      newRules = state.mockRules.map((rule) {
        if (rule.id == id) {
          return rule.copyWith(enabled: false);
        }
        return rule;
      }).toList();
    }
    
    state = state.copyWith(mockRules: newRules);
    await _mockRuleStore.save(newRules);
  }
}
