import 'package:flutter/material.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';

import 'data/services/file_utils.dart';
import 'data/services/storage_utils.dart';

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
    names = await StorageUtils.loadNames();
    checkboxValues = await StorageUtils.loadCheckboxValues(names.length);
    serialNumbers =
        await StorageUtils.loadSerialNumbers([/* default serials */]);
    setState(() {});
  }

  Future<void> saveData() async =>
      StorageUtils.saveData(names, checkboxValues, serialNumbers);

  Future<void> exportData() async => FileUtils.exportToExcel(
      names, checkboxValues, serialNumbers, numberOfIndividuals);

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
                FileUtils.exportToExcel(
                    names, checkboxValues, serialNumbers, numberOfIndividuals);
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
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
                                          '${FileUtils.calculateTotalIndividuals(numberOfIndividuals) - FileUtils.calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals)}',
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
                                          '${(FileUtils.calculateProgress(checkboxValues, numberOfIndividuals) * 100).toStringAsFixed(2)}%',
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
                                          '${FileUtils.calculateTotalCheckedIndividuals(checkboxValues, numberOfIndividuals)}',
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
                                      text:
                                          '${FileUtils.calculateTotalSerialNumbers(checkboxValues)}',
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
                                      text:
                                          '${FileUtils.calculateTotalIndividuals(numberOfIndividuals)}',
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
                      value: FileUtils.calculateProgress(
                          checkboxValues, numberOfIndividuals),
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
