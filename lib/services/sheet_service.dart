import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SheetService {
  // ⚠️ YAHAN APNA NAYA GOOGLE APP SCRIPT URL DAALEIN ⚠️
  static const String scriptUrl = "YOUR_NEW_SCRIPT_URL_HERE";

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

  // 🚀 FOOLPROOF SYNC: Ye pehle data bhejega, fir wapas confirm karke PRO status layega
  static Future<String> syncUserProfile({
    required String name,
    required String phone,
    required String email, 
    required String selectedClass,
  }) async {
    try {
      // 1. Data Sheet par bhejna (Email ke sath)
      await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "email": email,
          "selected_class": selectedClass,
        }),
      );
      
      // 2. Sheet se 100% correct PRO status Direct GET request se mangwana
      final response = await http.get(Uri.parse("$scriptUrl?sheet=User ID"));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        for (var item in rawData) {
          final sheetPhone = item['Phone']?.toString() ?? item['phone']?.toString() ?? '';
          // Phone number match karke uska asli status return karna
          if (sheetPhone == phone) {
            return item['Subscription Status']?.toString().toUpperCase() ?? 'FREE';
          }
        }
      }
    } catch (e) {
      return 'FREE';
    }
    return 'FREE';
  }
}