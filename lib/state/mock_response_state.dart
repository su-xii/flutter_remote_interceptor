import '../model/mock_rule.dart';

class MockResponseState {
  final List<MockRule> mockRules;

  const MockResponseState({
    required this.mockRules,
  });

  factory MockResponseState.initial() {
    return MockResponseState(mockRules: []);
  }

  MockResponseState copyWith({
    List<MockRule>? mockRules,
  }) {
    return MockResponseState(
      mockRules: mockRules ?? this.mockRules,
    );
  }
}
