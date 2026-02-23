import 'package:flutter/material.dart';
import 'package:endswitcher/src/rust/api/endfield.dart';

class AppState extends ChangeNotifier {
  List<AccountInfo> accounts = [];
  bool isLoading = false;
  bool isGameInstalled = true;
  String currentStatusMessage = '';

  Future<void> loadAccounts() async {
    isLoading = true;
    notifyListeners();
    try {
      accounts = await getAccountList();
      await findLoginCachePath();
      isGameInstalled = true;
      currentStatusMessage = '就绪';
    } catch (e) {
      if (e.toString().contains("Endfield directory not found")) {
        isGameInstalled = false;
        currentStatusMessage = '未找到游戏目录';
      } else if (e.toString().contains("login_cache file not found")) {
        isGameInstalled = true;
        currentStatusMessage = '未登录任何账号';
      } else {
        currentStatusMessage = '加载错误: $e';
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> saveCurrent(String alias) async {
    try {
      await saveCurrentAccount(alias: alias);
      await loadAccounts();
    } catch (e) {
      throw Exception('保存失败: $e');
    }
  }

  Future<void> switchTo(String alias) async {
    try {
      await switchToAccount(alias: alias);
      await loadAccounts();
    } catch (e) {
      throw Exception('切换失败: $e');
    }
  }

  Future<void> delete(String alias) async {
    await deleteAccount(alias: alias);
    await loadAccounts();
  }
}
