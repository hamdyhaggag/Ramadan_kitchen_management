import 'package:shared_preferences/shared_preferences.dart';

class StorageUtils {
  static Future<List<String>> loadNames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('distributionNames') ?? [];
  }

  static Future<List<bool>> loadCheckboxValues(int length) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? checkboxStringValues =
        prefs.getStringList('distributionCheckboxValues');
    return checkboxStringValues != null
        ? checkboxStringValues.map((value) => value == 'true').toList()
        : List.generate(length, (index) => false);
  }

  static Future<List<int>> loadSerialNumbers(
      List<int> defaultSerialNumbers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('distributionSerialNumbers') ??
            defaultSerialNumbers.map((e) => e.toString()))
        .map(int.parse)
        .toList();
  }

  static Future<void> saveData(List<String> names, List<bool> checkboxValues,
      List<int> serialNumbers) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('distributionNames', names);
    await prefs.setStringList('distributionCheckboxValues',
        checkboxValues.map((value) => value.toString()).toList());
    await prefs.setStringList('distributionSerialNumbers',
        serialNumbers.map((e) => e.toString()).toList());
  }
}
