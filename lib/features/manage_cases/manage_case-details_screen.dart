import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_colors.dart';
import '../../core/widgets/general_button.dart';
import '../donation/presentation/views/case_details_screen.dart';
import 'logic/cases_cubit.dart';
import 'logic/cases_state.dart';

class ManageCaseDetailsScreen extends StatelessWidget {
  const ManageCaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحالات'),
        centerTitle: true,
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
      "الاسم": "",
      "عدد الأفراد": '',
      "جاهزة": false,
      "هنا؟": false,
    });
  }

  void _editCase(int index) {
    final caseData = widget.cases[index];
    if (caseData['id'] == null) return;

    final nameController = TextEditingController(text: caseData["الاسم"]);
    final membersController =
        TextEditingController(text: caseData["عدد الأفراد"].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: AppColors.whiteColor,
          title: const Text("تعديل الحالة"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  cursorColor: AppColors.primaryColor,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: membersController,
                  cursorColor: AppColors.primaryColor,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "عدد الأفراد",
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "إلغاء",
                style: TextStyle(color: AppColors.blackColor),
              ),
            ),
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
              child: const Text(
                "حفظ",
                style: TextStyle(color: AppColors.primaryColor),
              ),
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
    final sortedCases = List<Map<String, dynamic>>.from(widget.cases)
      ..sort((a, b) => (a['الرقم'] as int).compareTo(b['الرقم'] as int));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: sortedCases.length,
            itemBuilder: (context, index) {
              final caseData = sortedCases[index];
              return Card(
                color: AppColors.whiteColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    caseData["الاسم"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("عدد الأفراد: ${caseData["عدد الأفراد"]}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.green),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: BlocProvider.of<CasesCubit>(context),
                              child: CaseDetailsScreen(caseData: caseData),
                            ),
                          ),
                        ),
                      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GeneralButton(
            text: 'إضافة حالة جديدة',
            backgroundColor: AppColors.primaryColor,
            textColor: AppColors.whiteColor,
            onPressed: _addNewCase,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GeneralButton(
            text: 'رجوع',
            backgroundColor: AppColors.secondaryColor,
            textColor: AppColors.whiteColor,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
