import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/page/global_mock_page.dart';
import 'package:remote_interceptor/page/page_mock_page.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/state/home_state.dart';

/// Mock 模式页面（顶层容器）。
///
/// 结构对齐拦截编辑页（`ResponseEditPage`）：顶部策略提示栏 + TabBar + TabBarView。
/// 两个 Tab 分别是「全局 Mock」与「页面级 Mock」，**二者互斥、同一时刻只有一个生效**，
/// 且「Tab 切换即策略切换」（见 PRD 决策 D3）。
class MockResponsePage extends ConsumerStatefulWidget {
  const MockResponsePage({super.key});

  @override
  ConsumerState<MockResponsePage> createState() => _MockResponsePageState();
}

class _MockResponsePageState extends ConsumerState<MockResponsePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 初始 Tab 与当前生效策略保持一致，避免页面重建后「Tab 与策略」不同步
    final strategy = ref.read(homeViewModelProvider).mockStrategy;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: strategy == MockStrategy.page ? 1 : 0,
    );
    _tabController.addListener(_syncMockStrategy);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncMockStrategy);
    _tabController.dispose();
    super.dispose();
  }

  /// Tab 即策略：切到「全局 Mock」→ 全局策略生效；切到「页面级 Mock」→ 页面级策略生效。
  ///
  /// 由 `HomeViewModel.switchMockStrategy` 保证幂等（策略相同则直接返回），
  /// 因此这里无需处理动画期间的重复回调。
  void _syncMockStrategy() {
    final strategy = _tabController.index == 0
        ? MockStrategy.global
        : MockStrategy.page;
    ref.read(homeViewModelProvider.notifier).switchMockStrategy(strategy);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);
    final strategy = ref.watch(homeViewModelProvider).mockStrategy;

    return Scaffold(
      backgroundColor: colors.bgPage,
      body: Column(
        children: [
          _buildStrategyBar(strategy, colors),
          _buildTabBar(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                GlobalMockPage(),
                PageMockPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 生效策略提示栏：明确「两种 Mock 互斥，当前只有一个生效」
  Widget _buildStrategyBar(MockStrategy strategy, AppColors colors) {
    final isGlobal = strategy == MockStrategy.global;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colors.primary.withOpacity(0.06),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前生效：${isGlobal ? '全局 Mock' : '页面级 Mock'}（两者互斥，仅一个生效）',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppColors colors) {
    return Container(
      color: colors.bgCard,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 20),
                SizedBox(width: 6),
                Text('全局 Mock', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, size: 20),
                SizedBox(width: 6),
                Text('页面级 Mock', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
