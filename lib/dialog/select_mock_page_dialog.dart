import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/model/mock_page.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';
import 'package:remote_interceptor/providers/viemodel_provider.dart';
import 'package:remote_interceptor/widgets/page_icon_avatar.dart';

/// 选中页面后的回调
typedef OnMockPageSelected = void Function(MockPageConfig page);

/// 选择「页面级 Mock」页面的弹窗。
///
/// 列表取自页面级 Mock 的配置（`mockPageViewModelProvider`），
/// 用于把「请求记录」里的某条响应数据添加到指定页面下。
/// 允许重复添加（同一接口可存在多条配置，后添加的生效），因此每次选择都会
/// 在目标页面下新增一条接口配置。
/// 选中后会自动关闭弹窗，再由调用方完成写入。
class SelectMockPageDialog extends ConsumerWidget {
  final OnMockPageSelected onSelected;

  const SelectMockPageDialog({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeProvider);
    final state = ref.watch(mockPageViewModelProvider);
    final pages = state.pages;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined,
                        size: 24, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '添加到页面Mock',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '选择要添加到的页面',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colors.textSecondary.withOpacity(0.12),
            ),
            if (pages.isEmpty)
              _buildEmptyState(colors)
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return _buildPageItem(
                      context,
                      colors,
                      page,
                      isCurrent: state.currentPageId == page.id,
                    );
                  },
                ),
              ),
            Divider(
              height: 1,
              color: colors.textSecondary.withOpacity(0.12),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个页面选项
  Widget _buildPageItem(
    BuildContext context,
    AppColors colors,
    MockPageConfig page, {
    required bool isCurrent,
  }) {
    return InkWell(
      onTap: () {
        onSelected(page);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            PageIconAvatar(
              char: page.displayIconChar,
              colorIndex: page.colorIndex,
              size: 40,
            ),
            const SizedBox(width: 12),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '当前页面',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${page.route} · ${page.apis.length} 个接口',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// 本地还没有任何页面时的空态
  Widget _buildEmptyState(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: colors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
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
            '请先在「Mock 模式 → 页面级 Mock」中添加页面',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
