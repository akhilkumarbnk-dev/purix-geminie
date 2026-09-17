import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SheetService {
  static const String scriptUrl = "https://script.google.com/macros/s/AKfycbw8YaS01il6eloEcKpxOUN7_HDxANf_lkj6oY1nFRKT-ZEVRqG4yzElpLku9sVVhboKcQ/exec";

  static Future<List<Map<String, dynamic>>> fetchSheetData(String sheetName, {bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cache_data_$sheetName';
      final timeKey = 'cache_time_$sheetName';

      if (!forceRefresh) {
        final cachedString = prefs.getString(cacheKey);
        final cachedTimeStr = prefs.getString(timeKey);
        if (cachedString != null && cachedTimeStr != null) {
          if (DateTime.now().difference(DateTime.parse(cachedTimeStr)).inHours < 12) {
            return List<Map<String, dynamic>>.from(jsonDecode(cachedString));
          }
        }
      }

      final response = await http.get(Uri.parse('$scriptUrl?sheet=${Uri.encodeComponent(sheetName)}'));
      if (response.statusCode == 200 || response.statusCode == 302) {
        await prefs.setString(cacheKey, response.body);
        await prefs.setString(timeKey, DateTime.now().toIso8601String());
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cache_data_$sheetName');
      if (cachedString != null) return List<Map<String, dynamic>>.from(jsonDecode(cachedString));
      return [];
    }
  }

  static Future<String> syncUserProfile({required String name, required String phone, required String email, required String selectedClass}) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "phone": phone, "email": email, "selected_class": selectedClass}),
      );
      if (response.statusCode == 200 || response.statusCode == 302) {
        return jsonDecode(response.body)["subscription"] ?? "FREE";
      }
      return "FREE";
    } catch (e) {
      return "FREE";
    }
  }
}