import 'package:flutter/material.dart';

import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/general_button.dart';

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
    casesData = List.from(widget.casesData);
  }

  void _addNewCase() {
    setState(() {
      casesData.add({
        "الرقم": casesData.length + 1,
        "الاسم": "اسم جديد",
        "عدد الأفراد": 1,
        "جاهزة": false,
        "هنا؟": false,
      });
    });
  }

  void _editCase(int index) {
    TextEditingController nameController =
        TextEditingController(text: casesData[index]["الاسم"]);
    TextEditingController membersController =
        TextEditingController(text: casesData[index]["عدد الأفراد"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("تعديل الحالة"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                setState(() {
                  casesData[index]["الاسم"] = nameController.text;
                  casesData[index]["عدد الأفراد"] =
                      int.tryParse(membersController.text) ?? 1;
                });
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة القيم'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: casesData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
