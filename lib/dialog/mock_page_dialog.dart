import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/model/mock_page.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';

/// 页面配置的保存回调（新增 / 修改共用）
typedef OnPageSave = void Function({
  required String name,
  required String route,
});

/// 新增 / 修改「页面级 Mock」页面配置的弹窗：填写页面名与路由地址。
///
/// [page] 为 `null` 时表示新增；否则为修改，会把已有的页面名与路由地址带入表单。
/// 新建的页面初始没有任何接口与路由入参，需进入详情页后继续补充。
class MockPageDialog extends ConsumerStatefulWidget {
  /// 待修改的页面，`null` 表示新增
  final MockPageConfig? page;

  final OnPageSave onSave;

  const MockPageDialog({
    super.key,
    this.page,
    required this.onSave,
  });

  @override
  ConsumerState<MockPageDialog> createState() => _MockPageDialogState();
}

class _MockPageDialogState extends ConsumerState<MockPageDialog> {
  /// 页面名输入框
  late final TextEditingController _nameController;

  /// 路由地址输入框
  late final TextEditingController _routeController;

  /// 是否处于修改模式
  bool get _isEdit => widget.page != null;

  @override
  void initState() {
    super.initState();
    // 修改模式带入已有值，新增模式为空
    _nameController = TextEditingController(text: widget.page?.name ?? '');
    _routeController = TextEditingController(text: widget.page?.route ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  void _showTip(String message) {
    final colors = ref.read(themeProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    final route = _routeController.text.trim();
    if (name.isEmpty) {
      _showTip('请输入页面名');
      return;
    }
    if (route.isEmpty) {
      _showTip('请输入路由地址');
      return;
    }

    widget.onSave(name: name, route: route);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_note : Icons.add_box_outlined,
                    size: 24,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? '修改 Mock 页面' : '添加 Mock 页面',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        _isEdit
                            ? '修改页面名与路由地址'
                            : '后续可在详情页补充路由入参与接口 Mock 数据',
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
            const SizedBox(height: 24),
            _buildLabel('页面名', colors),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hintText: '例如：用户详情',
              prefixIcon: Icons.title,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildLabel('路由地址', colors),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _routeController,
              hintText: '例如：/user/detail',
              prefixIcon: Icons.link,
              colors: colors,
            ),
            const SizedBox(height: 8),
            Text(
              '路由地址会作为跳转指令的 page 参数下发给被调试端',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildLabel(String text, AppColors colors) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required AppColors colors,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: colors.textSecondary.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
