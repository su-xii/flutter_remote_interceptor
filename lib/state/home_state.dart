// 拦截器模式
enum InterceptorMode{
  edit,
  mock
}

/// Mock 策略：全局 Mock 与页面级 Mock **互斥**，同一时刻仅一个生效
enum MockStrategy {
  /// 全局 Mock：按全局 Mock 规则命中并改写所有接口响应
  global,

  /// 页面级 Mock：仅当前页面关联的接口被改写，其余走真实请求
  page,
}

// 首页状态类
class HomeState {
  final InterceptorMode interceptorMode;

  /// 当前生效的 Mock 策略（仅 [InterceptorMode.mock] 下有实际意义）
  final MockStrategy mockStrategy;

  HomeState({required this.interceptorMode, this.mockStrategy = MockStrategy.global});

  factory HomeState.initial() => HomeState(interceptorMode: InterceptorMode.edit);

  HomeState copyWith({
    InterceptorMode? interceptorMode,
    MockStrategy? mockStrategy,
  }){
    return HomeState(
      interceptorMode: interceptorMode ?? this.interceptorMode,
      mockStrategy: mockStrategy ?? this.mockStrategy,
    );
  }
}
