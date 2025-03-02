import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.group_work),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageCaseGroupsScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CasesCubit, CasesState>(
        builder: (context, state) {
          if (state is CasesLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Theme.of(context).primaryColor,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text('جاري تحميل الحالات...',
                      style: Theme.of(context).textTheme.bodyLarge)
                ],
              ),
            );
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
  late ScrollController _scrollController;
  int _previousCasesLength = 0;
  late TextEditingController _searchController;
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _previousCasesLength = widget.cases.length;
    _searchController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _ManageCaseDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cases.length > _previousCasesLength) {
      _previousCasesLength = widget.cases.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewCase() {
    final currentState = context.read<CasesCubit>().state;
    if (currentState is! CasesLoaded) return;
    final currentCases = currentState.cases;
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final membersController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("إضافة حالة جديدة"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "الرقم",
                    hintText: "أدخل الرقم يدويًا",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "الاسم",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: membersController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "عدد الأفراد",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء")),
            TextButton(
              onPressed: () {
                final number = int.tryParse(numberController.text);
                final members = int.tryParse(membersController.text) ?? 0;
                if (number == null || number <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("الرجاء إدخال رقم صحيح موجب")));
                  return;
                }
                if (currentCases.any((c) => c['الرقم'] == number)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("رقم الحالة موجود مسبقًا")));
                  return;
                }
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("الرجاء إدخال اسم الحالة")));
                  return;
                }
                if (members <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("الرجاء إدخال عدد أفراد صحيح")));
                  return;
                }
                context.read<CasesCubit>().addCase({
                  "الرقم": number,
                  "id": number.toString(),
                  "الاسم": nameController.text,
                  "عدد الأفراد": members,
                  "جاهزة": false,
                  "هنا؟": false,
                });
                Navigator.pop(context);
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  void _editCase(Map<String, dynamic> caseData) {
    if (caseData['id'] == null) return;
    final nameController = TextEditingController(text: caseData["الاسم"]);
    final membersController =
        TextEditingController(text: caseData["عدد الأفراد"].toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                        borderSide: BorderSide(color: AppColors.primaryColor)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryColor)),
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
                        borderSide: BorderSide(color: AppColors.primaryColor)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primaryColor)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء",
                    style: TextStyle(color: AppColors.blackColor))),
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
              child: const Text("حفظ",
                  style: TextStyle(color: AppColors.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحالة'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الحالة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CasesCubit>().deleteCase(docId);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = value.trim()),
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.grey.shade600),
          hintText: 'ابحث بالإسم ...',
          suffixIcon: _searchController.text.isEmpty
              ? IconButton(
                  icon: Icon(Icons.search),
                  color: Colors.grey.shade600,
                  disabledColor: Colors.grey.shade600,
                  onPressed: null)
              : IconButton(
                  icon: Icon(Icons.clear),
                  color: Colors.grey.shade600,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  }),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredCases = widget.cases.where((caseItem) {
      final name = caseItem["الاسم"].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();
    List<Map<String, dynamic>> sortedCases = filteredCases
      ..sort((a, b) => (a['الرقم'] as int).compareTo(b['الرقم'] as int));
    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: sortedCases.length,
            itemBuilder: (context, index) {
              final caseData = sortedCases[index];
              return Card(
                color: AppColors.whiteColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(caseData["الاسم"],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                    child: CaseDetailsScreen(
                                        caseData: caseData)))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editCase(caseData),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(caseData['id']),
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
        const SizedBox(height: 16),
      ],
    );
  }
}

class ManageCaseGroupsScreen extends StatefulWidget {
  const ManageCaseGroupsScreen({super.key});
  @override
  State<ManageCaseGroupsScreen> createState() => _ManageCaseGroupsScreenState();
}

class _ManageCaseGroupsScreenState extends State<ManageCaseGroupsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _caseNumbersController = TextEditingController();
  Future<void> _addOrUpdateGroup({String? groupId}) async {
    final groupName = _groupNameController.text.trim();
    final caseNumbersString = _caseNumbersController.text.trim();
    if (groupName.isEmpty || caseNumbersString.isEmpty) return;
    final caseNumbers = caseNumbersString
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
    final docId = groupId ?? groupName;
    await FirebaseFirestore.instance
        .collection('caseGroups')
        .doc(docId)
        .set({'caseNumbers': caseNumbers});
    _groupNameController.clear();
    _caseNumbersController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة المجموعات")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('caseGroups')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final customOrder = [
                  'الشنط الفردية',
                  'المجموعة الأولى',
                  'المجموعة الخامسة',
                  'المجموعة السابعة',
                  'المجموعة الثانية',
                  'المجموعة الثالثة',
                  'المجموعة الرابعة',
                  'المجموعة السادسة',
                  'المجموعة الثامنة',
                ];
                final groups = snapshot.data!.docs;
                groups.sort((a, b) => customOrder
                    .indexOf(a.id)
                    .compareTo(customOrder.indexOf(b.id)));
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final doc = groups[index];
                    final groupName = doc.id;
                    final caseNumbers =
                        List<int>.from(doc.get('caseNumbers') ?? []);
                    return ListTile(
                      title: Text(groupName),
                      subtitle: Text(caseNumbers.join(', ')),
                      onTap: () {
                        _groupNameController.text = groupName;
                        _caseNumbersController.text = caseNumbers.join(', ');
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("تحديث المجموعة"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                      controller: _groupNameController,
                                      decoration: const InputDecoration(
                                          labelText: "اسم المجموعة")),
                                  TextField(
                                      controller: _caseNumbersController,
                                      decoration: const InputDecoration(
                                          labelText:
                                              "أرقام الحالات (افصل بفاصلة)")),
                                ],
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("إلغاء")),
                                TextButton(
                                    onPressed: () {
                                      _addOrUpdateGroup(groupId: groupName);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("تحديث")),
                              ],
                            );
                          },
                        );
                      },
                      trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('caseGroups')
                                .doc(groupName)
                                .delete();
                          }),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              child: const Text("إضافة جروب جديد"),
              onPressed: () {
                _groupNameController.clear();
                _caseNumbersController.clear();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("إضافة مجموعة جديدة"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                              controller: _groupNameController,
                              decoration: const InputDecoration(
                                  labelText: "اسم المجموعة")),
                          SizedBox(height: 6),
                          TextField(
                              controller: _caseNumbersController,
                              decoration: const InputDecoration(
                                  labelText: "أرقام الحالات (افصل بفاصلة)")),
                        ],
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("إالغاء")),
                        SizedBox(height: 8),
                        TextButton(
                            onPressed: () {
                              _addOrUpdateGroup();
                              Navigator.pop(context);
                            },
                            child: const Text("إضافة")),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
