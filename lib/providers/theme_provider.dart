import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/notification_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDark = false;

  ThemeData get lightTheme => ThemeData.light();

  ThemeData get darkTheme => ThemeData.dark();

  void toggleTheme() {
    isDark = !isDark;
    NotificationService().showInstantNotification(
      title: 'Theme Changed',
      body: isDark ? 'Dark mode enabled' : 'Light mode enabled',
    );
    notifyListeners();
  }

  static Future<ThemeProvider> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final provider = ThemeProvider();
    provider.isDark = isDark;
    return provider;
  }

  Future<void> saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }
}
