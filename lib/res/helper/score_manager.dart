import 'package:shared_preferences/shared_preferences.dart';

Future<void> incrementScore(String playerName) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(playerName) ?? 0;
  await prefs.setInt(playerName, current + 1);
}
