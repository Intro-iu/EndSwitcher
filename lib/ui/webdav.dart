import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../src/rust/api/webdav.dart';
import '../state.dart';
import '../theme.dart';
import 'components.dart';

class WebDavPage extends StatefulWidget {
  const WebDavPage({super.key});
  @override
  State<WebDavPage> createState() => _WebDavPageState();
}

class _WebDavPageState extends State<WebDavPage> {
  final urlController = TextEditingController();
  final userController = TextEditingController();
  final passController = TextEditingController();
  final pathController = TextEditingController(text: '');
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await loadWebdavConfig();
      setState(() {
        urlController.text = config.url;
        userController.text = config.username;
        passController.text = config.password ?? '';
        pathController.text = config.path ?? '';
      });
    } catch (_) {}
  }

  Future<void> _saveConfig() async {
    final config = WebDavConfig(
      url: urlController.text.trim(),
      username: userController.text.trim(),
      password: passController.text.isNotEmpty ? passController.text : null,
      path: pathController.text.trim().isNotEmpty
          ? pathController.text.trim()
          : null,
    );
    try {
      await saveWebdavConfig(config: config);
      if (mounted) showEndfieldSnackBar(context, '网络配置已更新');
    } catch (e) {
      if (mounted) showEndfieldSnackBar(context, '配置失败: $e', isError: true);
    }
  }

  Future<void> _sync(bool upload) async {
    setState(() => isLoading = true);
    try {
      await _saveConfig();
      if (upload) {
        await syncToWebdav();
      } else {
        await syncFromWebdav();
        if (mounted) context.read<AppState>().loadAccounts();
      }
      if (mounted) showEndfieldSnackBar(context, '同步完成');
    } catch (e) {
      if (mounted) showEndfieldSnackBar(context, '传输中断: $e', isError: true);
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'WEBDAV CONFIGURATION \\\\',
            subtitle: '云端档案同步网络',
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BeveledContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WebDAV 配置',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: EndfieldColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            labelText: 'WebDAV 服务器地址',
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: userController,
                          decoration: const InputDecoration(
                            labelText: '账号',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '密码',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: pathController,
                          decoration: const InputDecoration(
                            labelText: '路径',
                            prefixIcon: Icon(Icons.folder_outlined),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 底部按钮行：保存节点(黄色)在左，上传/恢复(白色)在右
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            EndfieldButton(
                              label: '保存节点',
                              icon: Icons.save_alt,
                              onPressed: isLoading ? null : _saveConfig,
                            ),
                            Row(
                              children: [
                                if (isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: EndfieldColors.primary,
                                      ),
                                    ),
                                  ),
                                EndfieldButton(
                                  label: '上传配置',
                                  icon: Icons.cloud_upload,
                                  isPrimary: false,
                                  onPressed: isLoading
                                      ? null
                                      : () => _sync(true),
                                ),
                                const SizedBox(width: 12),
                                EndfieldButton(
                                  label: '恢复配置',
                                  icon: Icons.cloud_download,
                                  isPrimary: false,
                                  onPressed: isLoading
                                      ? null
                                      : () => _sync(false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
