import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import 'components.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _showSaveDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final aliasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '保存当前账号',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: EndfieldColors.primary),
          ),
          content: TextField(
            controller: aliasController,
            decoration: const InputDecoration(labelText: '账号别名'),
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EndfieldButton(
                  label: '取消',
                  icon: Icons.close,
                  isPrimary: false,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                EndfieldButton(
                  label: '保存',
                  icon: Icons.check,
                  onPressed: () async {
                    final alias = aliasController.text.trim();
                    if (alias.isEmpty) return;
                    Navigator.pop(context);
                    try {
                      await appState.saveCurrent(alias);
                      if (context.mounted) {
                        showEndfieldSnackBar(
                          context,
                          '账号 "$alias" 已保存',
                          isError: false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showEndfieldSnackBar(
                          context,
                          e.toString(),
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    String alias,
    AppState appState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '警告 \\\\ DELETE',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: EndfieldColors.danger),
          ),
          content: Text('确定要删除保存的账号 "$alias" 吗？此操作不可逆。'),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EndfieldButton(
                  label: '取消',
                  icon: Icons.close,
                  isPrimary: false,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                EndfieldButton(
                  label: '确认删除',
                  icon: Icons.delete_forever,
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await appState.delete(alias);
                      if (context.mounted) {
                        showEndfieldSnackBar(
                          context,
                          '账号 "$alias" 已删除',
                          isError: false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showEndfieldSnackBar(
                          context,
                          e.toString(),
                          isError: true,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'ACCOUNTS \\\\', subtitle: '账号管理面板'),
          const SizedBox(height: 32),

          // 游戏状态模块
          BeveledContainer(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                // 右侧 logo 剪影（避开 ONLINE 标签）
                Positioned(
                  right: 60,
                  top: 10,
                  bottom: 10,
                  child: Opacity(
                    opacity: 0.06,
                    child: SvgPicture.asset(
                      'assets/endfield-industries.svg',
                      height: 100,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '状态监控',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: EndfieldColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          color: appState.isGameInstalled
                              ? EndfieldColors.primary
                              : EndfieldColors.danger,
                          child: Text(
                            appState.isGameInstalled ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: EndfieldColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appState.currentStatusMessage,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        EndfieldButton(
                          label: '保存凭证',
                          icon: Icons.save,
                          onPressed:
                              (!appState.isGameInstalled ||
                                  appState.currentStatusMessage.contains('未登录'))
                              ? null
                              : () => _showSaveDialog(context),
                        ),
                        const SizedBox(width: 16),
                        EndfieldButton(
                          label: '刷新',
                          icon: Icons.refresh,
                          isPrimary: false,
                          onPressed: () => appState.loadAccounts(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            '账号列表',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: EndfieldColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: appState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: EndfieldColors.primary,
                    ),
                  )
                : appState.accounts.isEmpty
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: const Text(
                        '-- 无本地归档 --',
                        style: TextStyle(
                          color: EndfieldColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: false,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: appState.accounts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final acc = appState.accounts[index];
                      return BeveledContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              color: EndfieldColors.surfaceLight,
                              child: const Icon(
                                Icons.person_outline,
                                color: EndfieldColors.primary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.alias,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'UPDATED: ${DateTime.fromMillisecondsSinceEpoch(acc.updatedAt * 1000).toLocal()}',
                                    style: TextStyle(
                                      color: EndfieldColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            EndfieldButton(
                              label: '应用',
                              icon: Icons.login,
                              isPrimary: false,
                              onPressed: () async {
                                try {
                                  await appState.switchTo(acc.alias);
                                  if (context.mounted) {
                                    showEndfieldSnackBar(
                                      context,
                                      '已成功载入配置: ${acc.alias}，请启动游戏。',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showEndfieldSnackBar(
                                      context,
                                      e.toString(),
                                      isError: true,
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: EndfieldColors.danger,
                              ),
                              onPressed: () => _showDeleteConfirm(
                                context,
                                acc.alias,
                                appState,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
