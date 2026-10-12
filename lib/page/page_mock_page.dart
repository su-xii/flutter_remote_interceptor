import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/dialog/mock_api_dialog.dart';
import 'package:remote_interceptor/dialog/mock_page_dialog.dart';
import 'package:remote_interceptor/dialog/mock_page_params_dialog.dart';
import 'package:remote_interceptor/model/jump_result.dart';
import 'package:remote_interceptor/model/mock_page.dart';
import 'package:remote_interceptor/model/request_record.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/state/server_status_state.dart';
import 'package:remote_interceptor/widgets/api_method_badge.dart';
import 'package:remote_interceptor/widgets/context_menu.dart';
import 'package:remote_interceptor/widgets/hit_counter_widget.dart';
import 'package:remote_interceptor/widgets/json_preview.dart';
import 'package:remote_interceptor/widgets/page_icon_avatar.dart';

/// 页面级 Mock（Mock 模式下的第二个 Tab）。
///
/// 内部为二级导航：未选中页面时展示页面列表，选中后展示该页面的接口配置详情。
class PageMockPage extends ConsumerWidget {
  const PageMockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePage = ref.watch(mockPageViewModelProvider).activePage;
    if (activePage == null) return const _PageMockListView();
    return _PageMockDetailView(page: activePage);
  }
}

// -----------------------------------------------------------------------------
// 页面列表
// -----------------------------------------------------------------------------

class _PageMockListView extends ConsumerWidget {
  const _PageMockListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);
    final state = ref.watch(mockPageViewModelProvider);
    final notifier = ref.read(mockPageViewModelProvider.notifier);
    final pages = state.filteredPages;

    return Column(
      children: [
        _buildHeader(context, colors, ref, state.pages.length),
        _buildSearchBar(colors, notifier),
        if (state.groups.isNotEmpty)
          _buildGroupFilter(colors, notifier, state.groupFilter, state.groups),
        Expanded(
          child: pages.isEmpty
              ? _buildEmptyState(colors)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    // 右键弹出菜单：删除页面（与「请求记录」列表保持同一交互习惯）
                    // 以 pageId 作为 key：路由允许重复，只有 id 唯一
                    return ContextMenu(
                      key: ValueKey(page.id),
                      getMenuItems: () => [
                        ContextMenuItem(
                          label: '修改页面',
                          icon: Icons.edit_outlined,
                          onTap: () => _showEditPageDialog(context, ref, page),
                        ),
                        ContextMenuItem(
                          label: '删除页面',
                          icon: Icons.delete_outline,
                          isDestructive: true,
                          onTap: () =>
                              _confirmDeletePage(context, notifier, page),
                        ),
                      ],
                      child: _PageMockListItem(
                        page: page,
                        isCurrent: state.currentPageId == page.id,
                        onTap: () => notifier.openPage(page.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// 顶部标题栏：页面数量 + 导入/导出入口
  Widget _buildHeader(
    BuildContext context,
    AppColors colors,
    WidgetRef ref,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 22, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            'Mock 页面',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$count 个',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
          const Spacer(),
          // 新增页面（本地无任何内置数据，页面均由用户创建或导入）
          IconButton(
            tooltip: '添加页面',
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: colors.primary,
            onPressed: () => _showAddPageDialog(context, ref),
          ),
          // 配置来源为本地，提供剪贴板方式的导入 / 导出（无需额外依赖）
          IconButton(
            tooltip: '导入配置（从剪贴板/手动粘贴）',
            icon: const Icon(Icons.file_download_outlined, size: 20),
            color: colors.textSecondary,
            onPressed: () => _showImportDialog(context),
          ),
          IconButton(
            tooltip: '导出配置',
            icon: const Icon(Icons.file_upload_outlined, size: 20),
            color: colors.textSecondary,
            onPressed: () => _showExportDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColors colors, dynamic notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) => notifier.updateKeyword(value),
        decoration: InputDecoration(
          hintText: '搜索页面名称 / 路由',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          filled: true,
          fillColor: colors.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildGroupFilter(
    AppColors colors,
    dynamic notifier,
    String? groupFilter,
    List<String> groups,
  ) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildGroupChip(colors, notifier, null, groupFilter, '全部'),
          ...groups.map((group) =>
              _buildGroupChip(colors, notifier, group, groupFilter, group)),
        ],
      ),
    );
  }

  Widget _buildGroupChip(
    AppColors colors,
    dynamic notifier,
    String? group,
    String? groupFilter,
    String label,
  ) {
    final selected = groupFilter == group;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => notifier.updateGroupFilter(group),
        labelStyle: TextStyle(
          color: selected ? Colors.white : colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        selectedColor: colors.primary,
        backgroundColor: colors.bgCard,
        side: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// 删除页面前的二次确认
  void _confirmDeletePage(
    BuildContext context,
    dynamic notifier,
    MockPageConfig page,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除页面「${page.name}」及其 ${page.apis.length} 个接口 Mock 配置吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              notifier.deletePage(page.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 56,
            color: colors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无 Mock 页面',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击右上角「+」添加页面，或通过「导入」批量粘贴配置',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 页面列表项
class _PageMockListItem extends StatelessWidget {
  final MockPageConfig page;
  final bool isCurrent;
  final VoidCallback onTap;

  const _PageMockListItem({
    required this.page,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = pageIconColor(page.colorIndex);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? iconColor.withOpacity(0.4) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                PageIconAvatar(
                  char: page.displayIconChar,
                  colorIndex: page.colorIndex,
                  size: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              page.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B1B32),
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B42A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                '当前页面',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00B42A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F5FA),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          page.route,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF7A8AA0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB6C3D6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 页面详情
// -----------------------------------------------------------------------------

class _PageMockDetailView extends ConsumerWidget {
  final MockPageConfig page;

  const _PageMockDetailView({required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);
    final state = ref.watch(mockPageViewModelProvider);
    final notifier = ref.read(mockPageViewModelProvider.notifier);
    final jumpResult = state.jumpResult;
    // 当前页面是否已「应用规则」（页面级 Mock 是否命中该页面）
    final isApplied = state.currentPageId == page.id;

    return Column(
      children: [
        _buildTopBar(context, colors, ref, notifier, jumpResult, isApplied),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildTitleRow(colors),
              const SizedBox(height: 16),
              _buildRouteParamsBlock(context, colors, notifier),
              const SizedBox(height: 18),
              _buildApiSectionHeader(context, colors, notifier),
              const SizedBox(height: 8),
              if (page.apis.isEmpty)
                _buildApiEmpty(colors)
              else
                ...List.generate(
                  page.apis.length,
                  (index) => _buildApiCard(
                    context,
                    colors,
                    notifier,
                    index,
                    page.apis[index],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 顶部操作栏：返回列表 + 进入页面 + 应用规则
  Widget _buildTopBar(
    BuildContext context,
    AppColors colors,
    WidgetRef ref,
    dynamic notifier,
    JumpResult jumpResult,
    bool isApplied,
  ) {
    final connected = ref.watch(serverStatusViewModelProvider)
            .clientConnectionStatus ==
        ClientConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      color: colors.bgCard,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => notifier.closePage(),
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('返回列表', style: TextStyle(fontSize: 14)),
          ),
          const Spacer(),
          if (jumpResult.status == JumpStatus.sending)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('下发中',
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: connected ? () => notifier.jumpToPage(page) : null,
            icon: const Icon(Icons.open_in_new, size: 15),
            label: const Text('进入页面', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.textSecondary.withOpacity(0.25),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 「应用规则」：只负责让该页面的 Mock 配置生效 / 取消生效，与跳转无关
          OutlinedButton.icon(
            onPressed: () => isApplied
                ? notifier.unapplyPage()
                : notifier.applyPage(page),
            icon: Icon(
              isApplied ? Icons.cancel_outlined : Icons.play_circle_outline,
              size: 15,
            ),
            label: Text(
              isApplied ? '取消应用' : '应用规则',
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isApplied ? colors.warning : colors.primary,
              side: BorderSide(
                color: (isApplied ? colors.warning : colors.primary)
                    .withOpacity(0.6),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(AppColors colors) {
    return Row(
      children: [
        PageIconAvatar(
          char: page.displayIconChar,
          colorIndex: page.colorIndex,
          size: 56,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.name,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5FA),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        page.route,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF7A8AA0),
                        ),
                      ),
                    ),
                  ),
                  if (page.group != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      page.group!,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 路由入参区块
  Widget _buildRouteParamsBlock(
    BuildContext context,
    AppColors colors,
    dynamic notifier,
  ) {
    final params = page.routeParams;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.04),
        border: Border.all(color: colors.primary.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '路由入参',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  params.isEmpty ? '无' : '${params.length} 个参数',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCardAction(
                colors,
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: () => _showEditParamsDialog(context, notifier),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: JsonPreview(
              data: params,
              emptyPlaceholder: '// 无路由入参',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiSectionHeader(
    BuildContext context,
    AppColors colors,
    dynamic notifier,
  ) {
    return Row(
      children: [
        Text(
          '接口配置',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${page.apis.length} 个',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.primary,
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _showAddApiDialog(context, notifier),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加接口', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildApiEmpty(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        '暂无接口配置',
        style: TextStyle(fontSize: 14, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildApiCard(
    BuildContext context,
    AppColors colors,
    dynamic notifier,
    int index,
    MockApiConfig api,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ApiMethodBadge(method: api.method),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  api.path,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (api.remark != null && api.remark!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              api.remark!,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withOpacity(0.08)),
            ),
            child: JsonPreview(data: api.response, maxHeight: 120),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // 启用开关：同页面下「方法 + 路径」相同的配置互斥，同时只生效一个
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: api.enabled,
                  onChanged: (_) => notifier.toggleApi(
                    pageId: page.id,
                    apiIndex: index,
                  ),
                  activeColor: colors.success,
                  activeTrackColor: colors.success.withOpacity(0.3),
                ),
              ),
              Text(
                api.enabled ? '已启用' : '已禁用',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: api.enabled ? colors.success : colors.textSecondary,
                ),
              ),
              // 命中计数（与全局 Mock 同款：次数增加时播放动画）
              const SizedBox(width: 10),
              HitCounterWidget(hitCount: api.hitCount),
              const Spacer(),
              _buildCardAction(
                colors,
                icon: Icons.edit_outlined,
                label: '编辑',
                onTap: () => _showEditApiDialog(context, notifier, index, api),
              ),
              const SizedBox(width: 8),
              _buildCardAction(
                colors,
                icon: Icons.delete_outline,
                label: '删除',
                color: colors.error,
                onTap: () => _confirmDeleteApi(context, notifier, index, api),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardAction(
    AppColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effective = color ?? colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: effective.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: effective),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: effective,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 编辑当前页面的路由入参
  void _showEditParamsDialog(BuildContext context, dynamic notifier) {
    showDialog(
      context: context,
      builder: (context) => MockPageParamsDialog(
        params: page.routeParams,
        onSave: (routeParams) {
          notifier.updatePageRouteParams(
            pageId: page.id,
            routeParams: routeParams,
          );
        },
      ),
    );
  }

  void _showAddApiDialog(BuildContext context, dynamic notifier) {
    showDialog(
      context: context,
      builder: (context) => MockApiDialog(
        onSave: ({
          required HttpMethod method,
          required String path,
          required String response,
          String? remark,
        }) {
          notifier.addApi(
            pageId: page.id,
            method: method,
            path: path,
            response: response,
            remark: remark,
          );
        },
      ),
    );
  }

  void _showEditApiDialog(
    BuildContext context,
    dynamic notifier,
    int index,
    MockApiConfig api,
  ) {
    showDialog(
      context: context,
      builder: (context) => MockApiDialog(
        api: api,
        onSave: ({
          required HttpMethod method,
          required String path,
          required String response,
          String? remark,
        }) {
          notifier.updateApi(
            pageId: page.id,
            apiIndex: index,
            method: method,
            path: path,
            response: response,
            remark: remark,
          );
        },
      ),
    );
  }

  void _confirmDeleteApi(
    BuildContext context,
    dynamic notifier,
    int index,
    MockApiConfig api,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除接口 ${api.method.name.toUpperCase()} ${api.path} 的 Mock 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              notifier.deleteApi(pageId: page.id, apiIndex: index);
              Navigator.pop(dialogContext);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 导入 / 导出（基于剪贴板，避免引入额外的文件选择依赖）
// -----------------------------------------------------------------------------

/// 新增页面：保存后停留在列表页
void _showAddPageDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => MockPageDialog(
      onSave: ({required String name, required String route}) {
        ref
            .read(mockPageViewModelProvider.notifier)
            .addPage(name: name, route: route);
      },
    ),
  );
}

/// 修改页面：编辑页面名与路由地址（按唯一 id 定位，路由允许重复）
void _showEditPageDialog(
  BuildContext context,
  WidgetRef ref,
  MockPageConfig page,
) {
  showDialog(
    context: context,
    builder: (context) => MockPageDialog(
      page: page,
      onSave: ({required String name, required String route}) {
        ref.read(mockPageViewModelProvider.notifier).updatePage(
              pageId: page.id,
              name: name,
              route: route,
            );
      },
    ),
  );
}

void _showImportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ImportConfigDialog(),
  );
}

void _showExportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _ExportConfigDialog(),
  );
}

class _ImportConfigDialog extends ConsumerStatefulWidget {
  const _ImportConfigDialog();

  @override
  ConsumerState<_ImportConfigDialog> createState() =>
      _ImportConfigDialogState();
}

class _ImportConfigDialogState extends ConsumerState<_ImportConfigDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 从剪贴板读取内容填入输入框，方便直接粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  Future<void> _handleImport() async {
    setState(() => _submitting = true);
    final error = await ref
        .read(mockPageViewModelProvider.notifier)
        .importFromJson(_controller.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    final colors = ref.read(themeProvider);
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('导入成功'),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导入页面配置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '粘贴页面配置 JSON 数组后将整体覆盖本地配置（含接口 Mock 数据）',
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 10,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '[ { "id": "...", "name": "...", "route": "...", "apis": [] } ]',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('从剪贴板粘贴',
                      style: TextStyle(fontSize: 13)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting ? null : _handleImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('确认导入'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportConfigDialog extends ConsumerWidget {
  const _ExportConfigDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);
    final jsonText =
        ref.read(mockPageViewModelProvider.notifier).exportToJson();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '导出页面配置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withOpacity(0.08)),
              ),
              child: JsonPreview(data: jsonText, maxHeight: 320),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: jsonText));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('已复制到剪贴板'),
                        backgroundColor: colors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制到剪贴板'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


