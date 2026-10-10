import 'dart:async';
import 'dart:convert';
import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/home_state.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/router/router_util.dart';


class HomeViewModel extends StateNotifier<HomeState> {

  final RemoteServer _remoteServer;
  final RequestHandler _editHandler;
  /// 全局 Mock 的请求处理（按全局规则命中改写）
  final RequestHandler _mockHandler;
  /// 页面级 Mock 的请求处理（仅当前页面关联接口命中改写）
  final RequestHandler _pageMockHandler;
  HomeViewModel(
    this._remoteServer,
    this._editHandler,
    this._mockHandler,
    this._pageMockHandler,
  ):super(HomeState.initial()){
    _switchRequestHandler();
  }

  final PageController pageController = PageController();

  @override
  void dispose() {
    _remoteServer.requestHandler = null;
    _remoteServer.disconnectClient();
    pageController.dispose();
    super.dispose();
  }

  void _switchRequestHandler(){
    _remoteServer.requestHandler = switch(state.interceptorMode){
      InterceptorMode.edit => _editHandler,
      // Mock 模式下再按「互斥的 Mock 策略」二选一：全局 / 页面级
      InterceptorMode.mock => switch(state.mockStrategy){
        MockStrategy.global => _mockHandler,
        MockStrategy.page => _pageMockHandler,
      },
    };
  }

  void switchMode() {
    state = state.copyWith(
        interceptorMode: InterceptorMode.values[
            (state.interceptorMode.index + 1) % InterceptorMode.values.length
        ]);
    _switchRequestHandler();
    pageController.animateToPage(state.interceptorMode.index, duration: Duration(milliseconds: 150), curve: Curves.linear);
  }

  /// 切换 Mock 策略。
  ///
  /// 全局 Mock 与页面级 Mock 互斥，同一时刻仅一个生效；
  /// 由 Mock 模式的 Tab 切换触发（Tab 即策略），切换即时生效、无需重启。
  void switchMockStrategy(MockStrategy strategy) {
    if (state.mockStrategy == strategy) return;
    state = state.copyWith(mockStrategy: strategy);
    _switchRequestHandler();
  }

  void goToDeviceDiscovery() {
    RouterUtil.goToDeviceDiscovery();
  }

  void switchDevice() {
    RouterUtil.goToDeviceDiscovery();
  }
}
