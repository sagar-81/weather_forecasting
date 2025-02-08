import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageUtils {
  static late SharedPreferences instance;

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
  }

  static String? get lastCity => instance.getString('last_city');
  static String? get lastTemp => instance.getString('last_temp');
  static String? get unit => instance.getString('unit');

  static Future<void> saveLastCity(String city) async {
    await instance.setString('last_city', city);
    log('Last searched city saved: $city');
  }

  static Future<void> saveLastTemp(String temp) async {
    await instance.setString("last_temp", temp);
    log("Last temperature saved: $temp");
  }

  static Future<void> saveUnit(String unitValue) async {
    await instance.setString('unit', unitValue);
    log('Unit preference saved: $unitValue');
  }

  static Future<void> clear() async {
    await instance.clear();
  }
}
