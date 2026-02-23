import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endswitcher/src/rust/frb_generated.dart';

import 'state.dart';
import 'theme.dart';
import 'ui/dashboard.dart';
import 'ui/webdav.dart';
import 'ui/components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadAccounts(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EndSwitcher',
      theme: EndfieldTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedIndustrialBackground(
        child: Row(
          children: [
            // 左侧工业风侧边栏 (添加些许出场动效)
            TweenAnimationBuilder(
              tween: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutExpo,
              builder: (context, val, child) {
                return FractionalTranslation(
                  translation: val,
                  child: Container(
                    width: 280,
                    decoration: const BoxDecoration(
                      color: EndfieldColors.surface,
                      border: Border(
                        right: BorderSide(
                          color: EndfieldColors.surfaceLight,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENDSWITCHER',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: EndfieldColors.textPrimary,
                                      letterSpacing: 2,
                                    ),
                              ),
                              Text(
                                'SYS.VERSION 1.0.1',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: EndfieldColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 64),

                        _NavButton(
                          title: '账号管理',
                          icon: Icons.storage_outlined,
                          isSelected: _currentIndex == 0,
                          onTap: () => _onNavTap(0),
                        ),
                        const SizedBox(height: 16),
                        _NavButton(
                          title: '配置同步',
                          icon: Icons.sync_alt,
                          isSelected: _currentIndex == 1,
                          onTap: () => _onNavTap(1),
                        ),

                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: EndfieldColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Endfield Industry',
                                style: TextStyle(
                                  color: EndfieldColors.textSecondary,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 右侧主内容区 (平滑色块 Wipe 或滑动幻灯片转场)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: _currentIndex == 0
                      ? const DashboardPage()
                      : const WebDavPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        height: 64,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 32 : 24),
        decoration: BoxDecoration(
          color: isSelected ? EndfieldColors.surfaceLight : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? EndfieldColors.primary : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? EndfieldColors.primary
                  : EndfieldColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? EndfieldColors.primary
                    : EndfieldColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
