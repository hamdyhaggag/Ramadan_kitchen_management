import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/manage_cases/widget/list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageCasesScreen extends StatefulWidget {
  const ManageCasesScreen({super.key});

  @override
  ManageCasesScreenState createState() => ManageCasesScreenState();
}

class ManageCasesScreenState extends State<ManageCasesScreen> {
  List<String> names = [];
  List<bool> checkboxValues = [];
  List<int> serialNumbers = [];
  List<int> numberOfIndividuals = [
    5,
    5,
    1,
    3,
    4,
    4,
    5,
    6,
    5,
    5,
    3,
    1,
    5,
    3,
    4,
    5,
    4,
    3,
    6,
    7,
    3,
    4,
    1,
    2,
    2,
    1,
    1,
    2,
    3,
    5,
    2,
    4,
    3,
    2,
    1,
    0,
    1,
    5,
    3,
    5,
    6,
    1,
    5,
    4,
    2,
    4,
    3,
    3,
    6,
    4,
    3,
    4,
    3,
    4,
    5,
    3,
    4,
    3,
    5,
    6,
    3,
    7,
    4,
    7,
    7,
    4,
    3,
    4,
    2,
    2,
    4,
    1,
    2,
    1,
    4,
    5,
    3,
    3,
    3,
    4,
    5
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    names = prefs.getStringList('distributionNames') ?? BagData.names;
    List<String>? checkboxStringValues =
        prefs.getStringList('distributionCheckboxValues');
    if (checkboxStringValues != null) {
      checkboxValues =
          checkboxStringValues.map((value) => value == 'true').toList();
    } else {
      checkboxValues = List.generate(names.length, (index) => false);
    }
    serialNumbers = (prefs.getStringList('distributionSerialNumbers') ??
            BagData.serialNumbers.map((e) => e.toString()))
        .map(int.parse)
        .toList();
    setState(() {});
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('distributionNames', names);
    List<String> checkboxStringValues =
        checkboxValues.map((value) => value.toString()).toList();
    await prefs.setStringList(
        'distributionCheckboxValues', checkboxStringValues);
    await prefs.setStringList('distributionSerialNumbers',
        serialNumbers.map((e) => e.toString()).toList());
  }

  Future<String> getFilePath() async {
    final directory = await getExternalStorageDirectory();
    String currentDate =
        DateTime.now().toString().split(' ')[0].replaceAll('-', '_');
    return '${directory?.path}/IftarReport_$currentDate.xlsx';
  }

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers for additional data
    sheet.appendRow([
      'عدد الأفراد المتبقي',
      'نسبة الإكتمال',
      'عدد الشنط',
      'إجمالي عدد الأفراد'
    ]);

    // Add data for the additional rows
    sheet.appendRow([
      '${calculateTotalIndividuals() - calculateTotalCheckedIndividuals()}',
      '${(calculateProgress() * 100).toStringAsFixed(2)}%',
      '${calculateTotalSerialNumbers()}',
      '${calculateTotalIndividuals()}'
    ]);

    // Add headers for existing data
    sheet.appendRow(['رقم الشنطة', 'الإسم', 'جاهز']);

    // Add existing data rows
    for (int i = 0; i < names.length; i++) {
      sheet.appendRow([
        serialNumbers[i],
        names[i],
        checkboxValues[i] ? 'تم التوزيع' : 'لم يتم التوزيع'
      ]);
    }

    File file = File(await getFilePath());
    await file.writeAsBytes(excel.encode()!);

    String filePath = file.path;
    Fluttertoast.showToast(
      msg: 'تم الحفظ في $filePath',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void filterUncheckedRows() {
    List<String> uncheckedNames = [];
    List<bool> uncheckedCheckboxValues = [];
    List<int> uncheckedSerialNumbers = [];

    for (int i = 0; i < names.length; i++) {
      if (!checkboxValues[i]) {
        uncheckedNames.add(names[i]);
        uncheckedCheckboxValues.add(checkboxValues[i]);
        uncheckedSerialNumbers.add(serialNumbers[i]);
      }
    }

    setState(() {
      names = uncheckedNames;
      checkboxValues = uncheckedCheckboxValues;
      serialNumbers = uncheckedSerialNumbers;
    });
    saveData();
  }

  int countActiveCheckboxes() {
    int count = 0;
    for (bool value in checkboxValues) {
      if (value) {
        count++;
      }
    }
    return count;
  }

  double calculateProgress() {
    int totalIndividuals = calculateTotalIndividuals();
    int totalCheckedIndividuals = calculateTotalCheckedIndividuals();
    if (totalIndividuals == 0) {
      return 0.0; // Avoid division by zero
    }
    return totalCheckedIndividuals / totalIndividuals;
  }

  int calculateTotalIndividuals() {
    return numberOfIndividuals.reduce((value, element) => value + element);
  }

  int calculateTotalSerialNumbers() {
    int totalSerialNumbers = 0;
    for (int i = 0; i < checkboxValues.length; i++) {
      if (!checkboxValues[i]) {
        // If the checkbox is not checked, increment the total serial numbers count
        totalSerialNumbers++;
      }
    }
    return totalSerialNumbers;
  }

  int calculateTotalCheckedIndividuals() {
    int totalChecked = 0;
    for (int i = 0; i < checkboxValues.length; i++) {
      if (checkboxValues[i]) {
        totalChecked += numberOfIndividuals[i];
      }
    }
    return totalChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: const Text(
            'التجهيز  و التوزيع ',
            style: TextStyle(fontFamily: 'DIN', color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                exportToExcel();
              },
              icon: const Icon(Icons.import_export, color: Colors.white),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.001),
                  const Flexible(
                    flex: 1,
                    child: Text(
                      'رقم الشنطة ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'DIN'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.08),
                  const Flexible(
                    flex: 1,
                    child: Text(
                      'الإســـم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'DIN'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.06),
                  const Flexible(
                    flex: 1,
                    child: Text(
                      'عدد الأفراد  ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'DIN'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Flexible(
                    flex: 1,
                    child: Text(
                      'جاهزة ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontFamily: 'DIN'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.002),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Expanded(
                child: ListView.builder(
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width * 0.02),
                        child: Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: TextFormField(
                                initialValue: serialNumbers[index].toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    serialNumbers[index] =
                                        int.tryParse(value) ?? 0;
                                  });
                                  saveData();
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Flexible(
                              flex: 4,
                              child: TextFormField(
                                initialValue: names[index],
                                style: TextStyle(
                                    fontFamily: 'DIN',
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04),
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.name,
                                textDirection: TextDirection.rtl,
                                onChanged: (value) {
                                  setState(() {
                                    names[index] = value;
                                  });
                                  saveData();
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Flexible(
                              flex: 1,
                              child: TextFormField(
                                initialValue:
                                    numberOfIndividuals[index].toString(),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    numberOfIndividuals[index] =
                                        int.tryParse(value) ?? 0;
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.primaryColor),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Flexible(
                              flex: 1,
                              child: Checkbox(
                                activeColor: AppColors.primaryColor,
                                value: checkboxValues[index],
                                onChanged: (newValue) {
                                  setState(() {
                                    checkboxValues[index] = newValue!;
                                  });
                                  saveData();
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.02),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width * 0.03),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: ' عدد الأفراد المتبقية: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.035,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${calculateTotalIndividuals() - calculateTotalCheckedIndividuals()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: ' نسبة الإكتمال : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'DIN',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${(calculateProgress() * 100).toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: ' عدد الأفراد الذي تم توزيعه  : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'DIN',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${calculateTotalCheckedIndividuals()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.00),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: '  عدد الشنط : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'DIN',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${calculateTotalSerialNumbers()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  text: '  العدد الكلي : ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'DIN',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${calculateTotalIndividuals()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'DIN',
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                                0.045,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: calculateProgress(),
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primaryColor,
          onPressed: () {
            deactivateCheckedBoxes();
          },
          child: const Icon(Icons.clear_outlined, color: Colors.white),
        ),
      ),
    );
  }

  void deactivateCheckedBoxes() {
    setState(() {
      for (int i = 0; i < checkboxValues.length; i++) {
        checkboxValues[i] = false;
      }
    });
    saveData();
  }
}
