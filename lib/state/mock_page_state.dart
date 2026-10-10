import 'package:remote_interceptor/model/jump_result.dart';
import 'package:remote_interceptor/model/mock_page.dart';

/// 页面级 Mock 的状态
class MockPageState {
  /// 全部页面配置
  final List<MockPageConfig> pages;

  /// 搜索关键字（匹配页面名称 / 路由）
  final String keyword;

  /// 分组筛选，`null` 表示「全部」
  final String? groupFilter;

  /// 详情页正在查看的页面 id（Tab 内的二级导航状态），`null` 表示停留在列表页
  final String? activePageId;

  /// 当前生效页面 id —— 页面级 Mock 的命中依据（桌面端乐观跟踪，见 PRD D11）
  final String? currentPageId;

  /// 「进入页面」按钮的指令状态
  final JumpResult jumpResult;

  const MockPageState({
    required this.pages,
    this.keyword = '',
    this.groupFilter,
    this.activePageId,
    this.currentPageId,
    this.jumpResult = JumpResult.idle,
  });

  factory MockPageState.initial() => const MockPageState(pages: []);

  /// 按关键字 + 分组过滤后的页面列表
  List<MockPageConfig> get filteredPages {
    final kw = keyword.trim().toLowerCase();
    return pages.where((page) {
      if (groupFilter != null && page.group != groupFilter) return false;
      if (kw.isEmpty) return true;
      return page.name.toLowerCase().contains(kw) ||
          page.route.toLowerCase().contains(kw);
    }).toList();
  }

  /// 全部分组（去重，用于筛选下拉）
  List<String> get groups {
    final result = <String>[];
    for (final page in pages) {
      final group = page.group;
      if (group != null && group.isNotEmpty && !result.contains(group)) {
        result.add(group);
      }
    }
    return result;
  }

  /// 详情页正在查看的页面配置，列表页时为 `null`
  MockPageConfig? get activePage {
    final id = activePageId;
    if (id == null) return null;
    for (final page in pages) {
      if (page.id == id) return page;
    }
    return null;
  }

  /// 当前生效的页面配置（页面级 Mock 命中依据），未选中时为 `null`
  MockPageConfig? get currentPage {
    final id = currentPageId;
    if (id == null) return null;
    for (final page in pages) {
      if (page.id == id) return page;
    }
    return null;
  }

  /// 是否正在请求中（禁止重复点击「进入页面」）
  bool get isJumping => jumpResult.status == JumpStatus.sending;

  MockPageState copyWith({
    List<MockPageConfig>? pages,
    String? keyword,
    String? groupFilter,
    bool clearGroupFilter = false,
    String? activePageId,
    bool clearActivePageId = false,
    String? currentPageId,
    bool clearCurrentPageId = false,
    JumpResult? jumpResult,
  }) {
    return MockPageState(
      pages: pages ?? this.pages,
      keyword: keyword ?? this.keyword,
      groupFilter: clearGroupFilter ? null : (groupFilter ?? this.groupFilter),
      activePageId: clearActivePageId ? null : (activePageId ?? this.activePageId),
      currentPageId: clearCurrentPageId ? null : (currentPageId ?? this.currentPageId),
      jumpResult: jumpResult ?? this.jumpResult,
    );
  }
}
