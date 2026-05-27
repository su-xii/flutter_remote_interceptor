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
  final RequestHandler _mockHandler;
  HomeViewModel(this._remoteServer,this._editHandler,this._mockHandler):super(HomeState.initial()){
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
      InterceptorMode.mock => _mockHandler,
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

  void goToDeviceDiscovery() {
    RouterUtil.goToDeviceDiscovery();
  }

  void switchDevice() {
    RouterUtil.goToDeviceDiscovery();
  }
}
