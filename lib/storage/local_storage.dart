import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageUtils {
  static late final SharedPreferences instance;
  static Future<SharedPreferences> init() async => instance = await SharedPreferences.getInstance();

  static String? get unit => instance.getString('unit');
  static String? get lastCity => instance.getString('city');
  static String? get lastTemp => instance.getString('temp');

  static Future<void>? savelastCity(String id) async {
    await instance.setString('city', id);
    log('lastCity saved to localstorage = >  $id');
  }

  static Future<void>? saveUnit(String id) async {
    await instance.setString('unit', id);
    log('lastCity saved to localstorage = >  $id');
  }

  static Future<void> savelastTemp(String long) async {
    await instance.setString("temp", long);
    log("lastTemp  = > $long");
  }

  static Future<void> clear() async {
    await instance.clear();
  }
}
