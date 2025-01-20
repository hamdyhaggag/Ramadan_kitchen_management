import 'dart:io';
import 'package:excel/excel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> getFilePath(String fileName) async {
    final directory = await getExternalStorageDirectory();
    String currentDate =
        DateTime.now().toString().split(' ')[0].replaceAll('-', '_');
    return '${directory?.path}/$fileName$currentDate.xlsx';
  }

  static Future<void> exportToExcel(
      List<String> names,
      List<bool> checkboxValues,
      List<int> serialNumbers,
      List<int> numberOfIndividuals) async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    sheet.appendRow([
      'عدد الأفراد المتبقي',
      'نسبة الإكتمال',
      'عدد الشنط',
      'إجمالي عدد الأفراد'
    ]);
    // Add data for additional rows
    sheet.appendRow([
      '${calculateTotalIndividuals(numberOfIndividuals) - calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals)}',
      '${(calculateProgress(checkboxValues, numberOfIndividuals) * 100).toStringAsFixed(2)}%',
      '${calculateTotalSerialNumbers(checkboxValues)}',
      '${calculateTotalIndividuals(numberOfIndividuals)}'
    ]);

    // Add headers for existing data
    sheet.appendRow(['رقم الشنطة', 'الإسم', 'جاهز']);
    for (int i = 0; i < names.length; i++) {
      sheet.appendRow([
        serialNumbers[i],
        names[i],
        checkboxValues[i] ? 'تم التوزيع' : 'لم يتم التوزيع'
      ]);
    }

    File file = File(await getFilePath('IftarReport_'));
    await file.writeAsBytes(excel.encode()!);

    Fluttertoast.showToast(
      msg: 'تم الحفظ في ${file.path}',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  static int calculateTotalIndividuals(List<int> numberOfIndividuals) =>
      numberOfIndividuals.reduce((value, element) => value + element);

  static int calculateTotalSerialNumbers(List<bool> checkboxValues) =>
      checkboxValues.where((value) => !value).length;

  static int calculateTotalCheckedIndividuals(
      List<bool> checkboxValues, List<int> numberOfIndividuals) {
    int totalChecked = 0;
    for (int i = 0; i < checkboxValues.length; i++) {
      if (checkboxValues[i]) totalChecked += numberOfIndividuals[i];
    }
    return totalChecked;
  }

  static double calculateProgress(
      List<bool> checkboxValues, List<int> numberOfIndividuals) {
    int totalIndividuals = calculateTotalIndividuals(numberOfIndividuals);
    int totalChecked =
        calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals);
    return totalIndividuals == 0 ? 0.0 : totalChecked / totalIndividuals;
  }
}
