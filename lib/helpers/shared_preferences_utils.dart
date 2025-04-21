import 'package:shared_preferences/shared_preferences.dart';


class SharedPrefUtils {
  late SharedPreferences preferences;
  static bool _init = false;
  static SharedPrefUtils? _instance;

  factory SharedPrefUtils() {
    if (_instance == null) {
      _instance = SharedPrefUtils._(); // Create an instance only if it doesn't exist
    }
    return _instance!;
  }

  SharedPrefUtils._(); // Private constructor for the Singleton pattern

  Future init() async {
    if (!_init) {
      preferences = await SharedPreferences.getInstance();
      _init = true;
    }
    return preferences;
  }

  void setValue(String key, Object value) {
    switch (value.runtimeType) {
      case String:
        preferences.setString(key, value as String);
        break;
      case bool:
        preferences.setBool(key, value as bool);
        break;
      case int:
        preferences.setInt(key, value as int);
        break;
      default:
    }
  }

  Object getValue(String key, Object defaultValue) {
    switch (defaultValue.runtimeType) {
      case String:
        return preferences.getString(key) ?? "";
      case bool:
        return preferences.getBool(key) ?? false;
      case int:
        return preferences.getInt(key) ?? defaultValue;
      default:
        return defaultValue;
    }
  }
}
