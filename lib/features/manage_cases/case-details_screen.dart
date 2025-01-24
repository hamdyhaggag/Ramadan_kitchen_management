import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';

class ManageCaseDetailsScreen extends StatelessWidget {
  const ManageCaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحالات'),
      ),
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CasesError) {
            return Center(child: Text(state.message));
          }
          if (state is CasesLoaded) {
            return _ManageCaseDetailsContent(cases: state.cases);
          }
          return const Center(child: Text('No cases found'));
        },
      ),
    );
  }
}

class _ManageCaseDetailsContent extends StatefulWidget {
  final List<Map<String, dynamic>> cases;
  const _ManageCaseDetailsContent({required this.cases});

  @override
  State<_ManageCaseDetailsContent> createState() =>
      _ManageCaseDetailsContentState();
}

class _ManageCaseDetailsContentState extends State<_ManageCaseDetailsContent> {
  void _addNewCase() {
    final currentState = context.read<CasesCubit>().state;

    if (currentState is! CasesLoaded) return;

    final currentCases = currentState.cases;
    final newNumber = currentCases.isEmpty
        ? 1
        : (currentCases
                .map((e) => e['الرقم'] as int)
                .reduce((a, b) => a > b ? a : b)) +
            1;

    context.read<CasesCubit>().addCase({
      "الرقم": newNumber,
      "id": newNumber.toString(),
      "الاسم": "اسم جديد",
      "عدد الأفراد": 1,
      "جاهزة": false,
      "هنا؟": false,
    });
  }

  void _editCase(int index) {
    final caseData = widget.cases[index];
    if (caseData['id'] == null) return;

    TextEditingController nameController =
        TextEditingController(text: caseData["الاسم"]);
    TextEditingController membersController =
        TextEditingController(text: caseData["عدد الأفراد"].toString());

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
                context.read<CasesCubit>().updateCase(
                  caseData['id'],
                  {
                    "الاسم": nameController.text,
                    "عدد الأفراد": int.tryParse(membersController.text) ?? 1,
                  },
                );
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
    final docId = widget.cases[index]['id'];
    context.read<CasesCubit>().deleteCase(docId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.cases.length,
            itemBuilder: (context, index) {
              final caseData = widget.cases[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  title: Text(caseData["الاسم"]),
                  subtitle: Text("عدد الأفراد: ${caseData["عدد الأفراد"]}"),
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
          child: GeneralButton(
            text: 'إضافة حالة جديدة',
            backgroundColor: AppColors.primaryColor,
            textColor: AppColors.whiteColor,
            onPressed: _addNewCase,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
          child: GeneralButton(
            text: 'رجوع',
            backgroundColor: AppColors.secondaryColor,
            textColor: AppColors.whiteColor,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
