import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SheetService {
  // ⚠️ YAHAN APNA NAYA GOOGLE APP SCRIPT URL DAALEIN ⚠️
  static const String scriptUrl = "https://script.google.com/macros/s/AKfycbzSciFB_a0EfNSroQW0tPwcNdbYyxofBKR_CUhUoiDy7ABQDunrtCDUqozd-2BTiMjR8w/exec";

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

      final response = await http.get(Uri.parse("$scriptUrl?sheet=$sheetName"));
      if (response.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        await prefs.setString(cacheKey, jsonEncode(data));
        await prefs.setString(timeKey, DateTime.now().toIso8601String());
        return data;
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  // Naya Sync Function jo Email aur PRO status ko 100% handle karega
  static Future<String> syncUserProfile({
    required String name,
    required String phone,
    required String email, 
    required String selectedClass,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "email": email, // Ab Email Google Sheet tak jayega
          "selected_class": selectedClass,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 302) {
        final data = jsonDecode(response.body);
        return data['subscription'] ?? 'FREE'; // Yahan se PRO wapas app me aayega
      }
    } catch (e) {
      return 'FREE';
    }
    return 'FREE';
  }
}