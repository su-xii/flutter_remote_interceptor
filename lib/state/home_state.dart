// 拦截器模式
enum InterceptorMode{
  edit,
  mock
}

// 首页状态类
class HomeState {
  final InterceptorMode interceptorMode;
  HomeState({required this.interceptorMode});
  factory HomeState.initial() => HomeState(interceptorMode: InterceptorMode.edit);
  HomeState copyWith({InterceptorMode? interceptorMode}){
    return HomeState(interceptorMode: interceptorMode ?? this.interceptorMode);
  }
}
