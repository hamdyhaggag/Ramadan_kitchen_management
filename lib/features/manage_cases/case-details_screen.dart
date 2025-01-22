import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/cache/prefs.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';

class ManageCaseDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> casesData;

  const ManageCaseDetailsScreen({super.key, required this.casesData});

  @override
  State<ManageCaseDetailsScreen> createState() =>
      _ManageCaseDetailsScreenState();
}

class _ManageCaseDetailsScreenState extends State<ManageCaseDetailsScreen> {
  late List<Map<String, dynamic>> casesData;

  @override
  void initState() {
    super.initState();
    _loadCasesData();
  }

  void _loadCasesData() {
    final savedData = Prefs.getString('casesData');
    if (savedData.isNotEmpty) {
      casesData = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    } else {
      casesData = List.from(widget.casesData);
    }
  }

  void _saveCasesData() {
    Prefs.setString('casesData', jsonEncode(casesData));
  }

  void _addNewCase() {
    setState(() {
      int newId = casesData.isEmpty
          ? 1
          : casesData
                  .map((e) => e["الرقم"] as int)
                  .reduce((a, b) => a > b ? a : b) +
              1;
      casesData.add({
        "الرقم": newId,
        "الاسم": "اسم جديد",
        "عدد الأفراد": 1,
        "جاهزة": false,
        "هنا؟": false,
      });
    });
    _saveCasesData();
  }

  void _editCase(int index) {
    TextEditingController numberController =
        TextEditingController(text: casesData[index]["الرقم"].toString());
    TextEditingController nameController =
        TextEditingController(text: casesData[index]["الاسم"]);
    TextEditingController membersController =
        TextEditingController(text: casesData[index]["عدد الأفراد"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.whiteColor,
          title: const Text("تعديل الحالة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: "الرقم"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "الاسم"),
              ),
              TextField(
                controller: membersController,
                decoration: const InputDecoration(labelText: "عدد الأفراد"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int newNumber = int.tryParse(numberController.text) ?? -1;
                if (newNumber <= 0 ||
                    casesData.any((e) =>
                        e["الرقم"] == newNumber && e != casesData[index])) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("رقم غير صالح أو مكرر!")),
                  );
                  return;
                }
                setState(() {
                  casesData[index]["الرقم"] = newNumber;
                  casesData[index]["الاسم"] = nameController.text;
                  casesData[index]["عدد الأفراد"] =
                      int.tryParse(membersController.text) ?? 1;
                });
                _saveCasesData();
                Navigator.pop(context);
              },
              child: const Text("حفظ"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
          ],
        );
      },
    );
  }

  void _deleteCase(int index) {
    setState(() {
      casesData.removeAt(index);
      for (int i = 0; i < casesData.length; i++) {
        casesData[i]["الرقم"] = i + 1;
      }
    });
    _saveCasesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحالات'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: casesData.length,
              itemBuilder: (context, index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(casesData[index]["الاسم"]),
                    subtitle:
                        Text("عدد الأفراد: ${casesData[index]["عدد الأفراد"]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editCase(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCase(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: _addNewCase,
              child: GeneralButton(
                  text: 'إضافة حالة جديدة',
                  backgroundColor: AppColors.primaryColor,
                  textColor: AppColors.whiteColor),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
            child: GestureDetector(
              onTap: () {
                _saveCasesData();
                Navigator.pop(context, casesData);
              },
              child: GeneralButton(
                  text: 'حفظ التعديلات',
                  backgroundColor: AppColors.secondaryColor,
                  textColor: AppColors.whiteColor),
            ),
          ),
        ],
      ),
    );
  }
}
