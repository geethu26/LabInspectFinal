import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _pidkey = 'pid';

  static Future<void> setUserLoggedIn(bool isLoggedIn, String? pid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn); 
    await prefs.setString(_pidkey, pid??'');
  }

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey)??false;
  }

  static Future<String?> getPid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pidkey);
  }
}