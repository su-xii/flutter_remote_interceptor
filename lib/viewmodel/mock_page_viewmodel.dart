import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio_remote_interceptor/dio_remote_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/data/local/mock_page_store.dart';
import 'package:remote_interceptor/model/jump_result.dart';
import 'package:remote_interceptor/model/mock_page.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/server/remote_server.dart';
import 'package:remote_interceptor/state/mock_page_state.dart';
import 'package:remote_interceptor/state/server_status_state.dart';

/// 页面级 Mock 的 ViewModel。
///
/// 职责：
/// 1. 页面配置的加载 / 持久化 / 增删改；
/// 2. 列表页的搜索与分组筛选、详情页二级导航状态；
/// 3. 当前页面（桌面端乐观跟踪，PRD D11）维护；
/// 4. 页面级 Mock 的命中改写（作为桌面端 mock 模式下的一个 requestHandler）；
/// 5. 「进入页面」跳转指令的下发与回执状态。
class MockPageViewModel extends StateNotifier<MockPageState> {
  final MockPageStore _store;
  final RemoteServer _remoteServer;

  /// 指令回执订阅（桌面端收到的非请求类消息）
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  MockPageViewModel(this._store, this._remoteServer)
      : super(MockPageState.initial()) {
    _load();
    // 订阅指令回执，用于「进入页面」按钮的成功 / 失败回显
    _eventSubscription = _remoteServer.events.listen(_handleServerEvent);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// 加载本地配置。
  ///
  /// 不做任何内置数据兜底：本地无数据时展示空态，由用户通过「添加页面」或「导入」创建。
  Future<void> _load() async {
    final pages = await _store.load();
    state = state.copyWith(pages: pages ?? []);
  }

  // ---------------------------------------------------------------------------
  // 列表筛选 / 二级导航
  // ---------------------------------------------------------------------------

  /// 更新搜索关键字
  void updateKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }

  /// 更新分组筛选，传 `null` 表示全部
  void updateGroupFilter(String? group) {
    state = state.copyWith(
      groupFilter: group,
      clearGroupFilter: group == null,
    );
  }

  /// 打开某页面的详情
  void openPage(String pageId) {
    state = state.copyWith(activePageId: pageId);
  }

  /// 返回列表页
  void closePage() {
    state = state.copyWith(clearActivePageId: true);
  }

  // ---------------------------------------------------------------------------
  // 配置读写
  // ---------------------------------------------------------------------------

  /// 新增一个页面配置（新建时无接口、无路由入参）。
  ///
  /// 创建后停留在列表页，由用户自行进入详情页补充接口配置。
  Future<void> addPage({
    required String name,
    required String route,
  }) async {
    final page = MockPageConfig(
      id: _newPageId(),
      name: name,
      route: route,
      // 依次取色，保证相邻页面图标颜色不重复
      colorIndex: state.pages.length,
    );
    await _savePages([...state.pages, page]);
  }

  /// 修改页面配置（页面名 / 路由地址）。
  ///
  /// 按唯一的 id 定位，因此路由允许改为与其它页面相同；
  /// 路由变化会同步影响后续「进入页面」下发的 page 参数。
  Future<void> updatePage({
    required String pageId,
    required String name,
    required String route,
  }) async {
    final pages = state.pages
        .map((page) => page.id == pageId
            ? page.copyWith(name: name, route: route)
            : page)
        .toList();
    await _savePages(pages);
  }

  /// 删除指定页面配置。
  ///
  /// 若被删除的页面正好是详情页正在查看的页面或「当前页面」，
  /// 一并清空引用，避免后续操作指向已删除的数据。
  Future<void> deletePage(String pageId) async {
    final pages = state.pages.where((page) => page.id != pageId).toList();
    state = state.copyWith(
      pages: pages,
      clearActivePageId: state.activePageId == pageId,
      clearCurrentPageId: state.currentPageId == pageId,
    );
    await _store.save(pages);
  }

  /// 更新指定页面的路由入参
  Future<void> updatePageRouteParams({
    required String pageId,
    required Map<String, dynamic> routeParams,
  }) async {
    final pages = state.pages
        .map((page) => page.id == pageId
            ? page.copyWith(routeParams: routeParams)
            : page)
        .toList();
    await _savePages(pages);
  }

  /// 生成页面唯一标识（微秒时间戳，避免与已有 id 冲突）
  String _newPageId() => 'page_${DateTime.now().microsecondsSinceEpoch}';

  /// 更新某个接口的 Mock 配置（方法 / 路径 / 数据 / 备注）。
  ///
  /// 若该配置处于启用状态，同一页面下「相同 方法 + 路径」的其它配置会被自动禁用（互斥）。
  Future<void> updateApi({
    required String pageId,
    required int apiIndex,
    required HttpMethod method,
    required String path,
    required String response,
    String? remark,
  }) async {
    final pages = state.pages.map((page) {
      if (page.id != pageId) return page;
      if (apiIndex < 0 || apiIndex >= page.apis.length) return page;

      final apis = List<MockApiConfig>.from(page.apis);
      final target = apis[apiIndex].copyWith(
        method: method,
        path: path,
        response: response,
        remark: remark,
      );
      apis[apiIndex] = target;

      // 互斥：启用状态下，同一「方法 + 路径」的其它配置自动禁用
      if (target.enabled) {
        for (var i = 0; i < apis.length; i++) {
          if (i == apiIndex) continue;
          if (apis[i].method == method && apis[i].path == path) {
            apis[i] = apis[i].copyWith(enabled: false);
          }
        }
      }
      return page.copyWith(apis: apis);
    }).toList();
    await _savePages(pages);
  }

  /// 为指定页面新增一个接口配置。
  ///
  /// 新增项默认启用；若已存在同一「方法 + 路径」的启用配置，会被自动禁用（互斥）。
  Future<void> addApi({
    required String pageId,
    required HttpMethod method,
    required String path,
    required String response,
    String? remark,
  }) async {
    final pages = state.pages.map((page) {
      if (page.id != pageId) return page;
      final apis = List<MockApiConfig>.from(page.apis);
      for (var i = 0; i < apis.length; i++) {
        if (apis[i].method == method && apis[i].path == path) {
          apis[i] = apis[i].copyWith(enabled: false);
        }
      }
      apis.add(MockApiConfig(
        method: method,
        path: path,
        response: response,
        remark: remark,
      ));
      return page.copyWith(apis: apis);
    }).toList();
    await _savePages(pages);
  }

  /// 从「请求记录」把一次请求的响应数据添加到指定页面。
  ///
  /// 若该页面下已存在相同「方法 + 路径」的配置，则**覆盖其 Mock 数据**（避免产生重复配置），
  /// 否则新增一条启用配置。接口路径直接用上报的完整 URL，命中判定已兼容完整 URL 与纯路径。
  Future<void> upsertApiByRequest({
    required String pageId,
    required HttpMethod method,
    required String path,
    required String response,
  }) async {
    final pageIndex = state.pages.indexWhere((page) => page.id == pageId);
    if (pageIndex == -1) return;

    final page = state.pages[pageIndex];
    final existingIndex = page.apis.indexWhere(
      (api) => api.method == method && api.path == path,
    );

    if (existingIndex >= 0) {
      await updateApi(
        pageId: pageId,
        apiIndex: existingIndex,
        method: method,
        path: path,
        response: response,
        remark: page.apis[existingIndex].remark,
      );
      return;
    }

    await addApi(
      pageId: pageId,
      method: method,
      path: path,
      response: response,
    );
  }

  /// 切换某个接口配置的启用状态。
  ///
  /// 与全局 Mock 规则一致：同一页面下可以有多个配置，但「方法 + 路径」相同的配置**互斥**，
  /// 打开其中一个时，同组的其它配置会被自动禁用。
  Future<void> toggleApi({
    required String pageId,
    required int apiIndex,
  }) async {
    final pages = state.pages.map((page) {
      if (page.id != pageId) return page;
      if (apiIndex < 0 || apiIndex >= page.apis.length) return page;

      final target = page.apis[apiIndex];
      final willBeEnabled = !target.enabled;
      final apis = List<MockApiConfig>.from(page.apis);

      for (var i = 0; i < apis.length; i++) {
        if (i == apiIndex) {
          apis[i] = apis[i].copyWith(enabled: willBeEnabled);
          continue;
        }
        if (willBeEnabled &&
            apis[i].method == target.method &&
            apis[i].path == target.path) {
          apis[i] = apis[i].copyWith(enabled: false);
        }
      }
      return page.copyWith(apis: apis);
    }).toList();
    await _savePages(pages);
  }

  /// 删除指定页面的某个接口配置
  Future<void> deleteApi({
    required String pageId,
    required int apiIndex,
  }) async {
    final pages = state.pages.map((page) {
      if (page.id != pageId) return page;
      if (apiIndex < 0 || apiIndex >= page.apis.length) return page;
      final apis = List<MockApiConfig>.from(page.apis)..removeAt(apiIndex);
      return page.copyWith(apis: apis);
    }).toList();
    await _savePages(pages);
  }

  /// 导出当前全部页面配置为格式化 JSON 字符串
  String exportToJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(state.pages.map((e) => e.toJson()).toList());
  }

  /// 导入页面配置（整体覆盖）。
  ///
  /// 返回 `null` 表示成功，否则返回错误提示文案（供 UI 展示）。
  Future<String?> importFromJson(String jsonText) async {
    if (jsonText.trim().isEmpty) return '导入内容为空';
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) return '导入内容必须是页面配置数组（JSON Array）';
      final pages = decoded
          .whereType<Map>()
          .map((e) => MockPageConfig.fromJson(e.cast<String, dynamic>()))
          .toList();
      // 允许导入空数组 `[]`：用于清空本地全部页面配置
      if (decoded.isNotEmpty && pages.isEmpty) {
        return '未解析到任何页面配置';
      }
      await _savePages(pages);
      return null;
    } catch (e) {
      return 'JSON 解析失败: $e';
    }
  }

  Future<void> _savePages(List<MockPageConfig> pages) async {
    state = state.copyWith(pages: pages);
    await _store.save(pages);
  }

  // ---------------------------------------------------------------------------
  // 「进入页面」与「应用规则」：职责已拆分
  // ---------------------------------------------------------------------------

  /// 点击「进入页面」：**只下发跳转指令**，不再改变 Mock 的生效状态。
  ///
  /// 让该页面的配置生效由「应用规则」按钮负责（见 [applyPage] / [unapplyPage]）。
  void jumpToPage(MockPageConfig page) {
    if (state.isJumping) return;

    final commandId = _newCommandId();
    final command = RemoteCommand(
      commandId: commandId,
      action: RemoteCommandAction.jump,
      payload: {
        'pageId': page.id,
        'page': page.route,
        'arguments': page.routeParams,
      },
    );

    // 客户端未连接时直接失败，避免指令被静默丢弃
    if (_remoteServer.clientConnectionStatus !=
        ClientConnectionStatus.connected) {
      state = state.copyWith(
        jumpResult: JumpResult(
          status: JumpStatus.failure,
          commandId: commandId,
          message: '客户端未连接，指令未下发',
        ),
      );
      return;
    }

    state = state.copyWith(
      jumpResult: JumpResult(status: JumpStatus.sending, commandId: commandId),
    );
    _remoteServer.sendCommand(command.toJson());
  }

  /// 应用规则：把指定页面设为「当前页面」，页面级 Mock 据此命中该页面的接口配置。
  ///
  /// 与 [jumpToPage] 完全解耦：只让配置生效，不向手机端下发任何指令，
  /// 因此客户端未连接时同样可用。
  void applyPage(MockPageConfig page) {
    state = state.copyWith(currentPageId: page.id);
  }

  /// 取消应用：清空当前页面，页面级 Mock 不再命中任何接口（全部走真实请求）。
  void unapplyPage() {
    state = state.copyWith(clearCurrentPageId: true);
  }

  /// 处理桌面端收到的非请求类消息（当前仅关心指令回执）
  void _handleServerEvent(Map<String, dynamic> message) {
    if (MessageType.fromValue(message['type']) != MessageType.commandResult) {
      return;
    }
    final commandId = message['commandId']?.toString();
    // 只处理本端最近一次下发的指令回执，避免过期回执覆盖状态
    final pendingId = state.jumpResult.commandId;
    if (pendingId != null && commandId != pendingId) return;

    final success = message['success'] == true;
    state = state.copyWith(
      jumpResult: JumpResult(
        status: success ? JumpStatus.success : JumpStatus.failure,
        commandId: commandId,
        message: success ? null : (message['message']?.toString() ?? '跳转失败'),
      ),
    );
  }

  /// 生成指令唯一标识（毫秒时间戳 + 随机数），与插件侧 WsClient 的 requestId 规则一致
  String _newCommandId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  // ---------------------------------------------------------------------------
  // 页面级 Mock 命中改写
  // ---------------------------------------------------------------------------

  /// 页面级 Mock 的请求处理入口（作为 mock 模式下 `RemoteServer.requestHandler` 的一种实现）。
  ///
  /// 命中规则：当前页面存在，且请求 `url + method` 命中该页面下某个已启用接口 →
  /// 用该接口的 Mock 数据替换 `data`；未命中则原样返回真实响应。
  Future<Map<String, dynamic>> handleRequest(
      Map<String, dynamic> requestData) async {
    final currentPage = state.currentPage;
    // 未选中任何页面：不做任何改写，全部走真实请求
    if (currentPage == null) return requestData;

    final requestOptions = requestData['requestOptions'];
    final uri = (requestOptions is Map ? requestOptions['uri'] : null)
            ?.toString() ??
        '';
    final method =
        (requestOptions is Map ? requestOptions['method'] : null)?.toString() ??
            '';

    var hitIndex = -1;
    for (var i = 0; i < currentPage.apis.length; i++) {
      final api = currentPage.apis[i];
      if (!api.enabled) continue;
      if (api.method.name.toUpperCase() != method.toUpperCase()) continue;
      if (_matchPath(api.path, uri)) {
        hitIndex = i;
        break;
      }
    }
    if (hitIndex == -1) return requestData;

    // 命中计数 +1（仅内存态）
    _increaseHitCount(currentPage.id, hitIndex);

    try {
      requestData['data'] = json.decode(currentPage.apis[hitIndex].response);
    } catch (e) {
      // Mock 数据不是合法 JSON：保持真实响应，避免打断请求链路
      debugPrint('[MockPageViewModel] Mock 数据解析失败，已跳过改写: $e');
    }
    return requestData;
  }

  /// 命中计数 +1。
  ///
  /// 与全局 Mock 规则保持一致：只更新内存状态、不落盘，重启后归零。
  void _increaseHitCount(String pageId, int apiIndex) {
    final pages = state.pages.map((page) {
      if (page.id != pageId) return page;
      if (apiIndex < 0 || apiIndex >= page.apis.length) return page;
      final apis = List<MockApiConfig>.from(page.apis);
      final target = apis[apiIndex];
      apis[apiIndex] = target.copyWith(hitCount: target.hitCount + 1);
      return page.copyWith(apis: apis);
    }).toList();
    state = state.copyWith(pages: pages);
  }

  /// 接口路径匹配。
  ///
  /// 兼容两种配置写法：完整 URL 与纯路径；比对前去掉 query / fragment，
  /// 因此 `https://api.x.com/api/user/profile?a=1` 可命中 `/api/user/profile`。
  bool _matchPath(String apiPath, String uri) {
    if (apiPath.isEmpty || uri.isEmpty) return false;
    final path = uri.split('?').first.split('#').first;
    return path == apiPath || path.endsWith(apiPath);
  }
}
