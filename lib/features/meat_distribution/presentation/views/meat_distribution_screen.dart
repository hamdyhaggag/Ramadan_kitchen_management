import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' as io;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/app_colors.dart';
import '../../data/models/meat_campaign_model.dart';
import '../../../manage_cases/logic/cases_cubit.dart';
import '../../../manage_cases/logic/cases_state.dart';
import '../../logic/meat_campaigns_cubit.dart';

class MeatDistributionScreen extends StatefulWidget {
  final MeatCampaign campaign;
  const MeatDistributionScreen({super.key, required this.campaign});

  @override
  State<MeatDistributionScreen> createState() => _MeatDistributionScreenState();
}

class _MeatDistributionScreenState extends State<MeatDistributionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track allocations fetched from firebase { caseNumber: weight }
  Map<String, double> _allocations = {};
  
  // Track local steppers values { caseNumber: currentStepperValue }
  final Map<String, double> _stepperValues = {};

  // For Filtering
  String _searchQuery = '';
  String? _selectedArea;

  // Excluded families for this campaign
  Set<String> _excludedCases = {};

  double get _totalDistributed => _allocations.values.fold(0.0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    if (context.read<CasesCubit>().state is! CasesLoaded) {
      context.read<CasesCubit>().loadCases();
    }
    _loadExcludedCases();
  }

  Future<void> _loadExcludedCases() async {
    final doc = await _firestore
        .collection('meat_campaigns')
        .doc(widget.campaign.id)
        .get();
    if (doc.exists && doc.data()!.containsKey('excludedCases')) {
      setState(() {
        _excludedCases = Set<String>.from(doc.data()!['excludedCases'] as List);
      });
    }
  }

  Future<void> _saveExcludedCases() async {
    await _firestore
        .collection('meat_campaigns')
        .doc(widget.campaign.id)
        .update({'excludedCases': _excludedCases.toList()});
  }

  Stream<QuerySnapshot> _getAllocationsStream() {
    return _firestore
        .collection('meat_campaigns')
        .doc(widget.campaign.id)
        .collection('allocations')
        .snapshots();
  }

  Future<void> _allocateMeat(Map<String, dynamic> caseItem, double weight) async {
    final caseNum = caseItem['الرقم'].toString();
    try {
      await _firestore
          .collection('meat_campaigns')
          .doc(widget.campaign.id)
          .collection('allocations')
          .doc(caseNum)
          .set({
        'caseNum': caseNum,
        'caseName': caseItem['الاسم'] ?? 'غير معروف',
        'membersCount': int.tryParse(caseItem['عدد الأفراد'].toString()) ?? 1,
        'weight': weight,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update total on the campaign itself seamlessly
      if (context.mounted) {
        final newTotal = _totalDistributed + (weight - (_allocations[caseNum] ?? 0.0)); 
        context.read<MeatCampaignsCubit>().updateDistributedWeight(widget.campaign.id, newTotal);
        
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('تم تسليم $weight كجم لأسرة ${caseItem['الاسم']}'),
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 4),
             action: SnackBarAction(
                label: 'تراجع',
                textColor: Colors.orangeAccent,
                onPressed: () => _removeAllocation(caseNum),
             ),
           ),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التسجيل: $e')));
      }
    }
  }

  Future<void> _removeAllocation(String caseNum) async {
     try {
       final oldWeight = _allocations[caseNum] ?? 0;
       await _firestore
          .collection('meat_campaigns')
          .doc(widget.campaign.id)
          .collection('allocations')
          .doc(caseNum)
          .delete();
          
       if (context.mounted) {
         context.read<MeatCampaignsCubit>().updateDistributedWeight(widget.campaign.id, _totalDistributed - oldWeight);
       }
     } catch (e) {
       // Error Handling
     }
  }

  void _confirmRemoveAllocation(BuildContext context, String caseNum, String caseName) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Text('تأكيد التراجع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
            ]
          ),
          content: Text('هل أنت متأكد من إلغاء تسليم اللحوم لأسرة "$caseName"؟\nسيتم استرداد الكمية للمجموع.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
               onPressed: () {
                 Navigator.pop(ctx);
                 _removeAllocation(caseNum);
               },
               child: const Text('نعم، تراجع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExcludedFamiliesSheet() {
    final casesState = context.read<CasesCubit>().state;
    if (casesState is! CasesLoaded) return;

    // Extract unique areas
    final Set<String> areas = {};
    for (var c in casesState.cases) {
       final ar = c['المنطقة']?.toString().trim();
       if (ar != null && ar.isNotEmpty) areas.add(ar);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String filterText = '';
        String? selectedArea;
        bool showOnlyExcluded = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = casesState.cases.where((c) {
              final name = c['الاسم']?.toString() ?? '';
              final number = c['الرقم']?.toString() ?? '';
              final area = c['المنطقة']?.toString().trim() ?? '';
              final isExcluded = _excludedCases.contains(number);

              final matchText = filterText.isEmpty || name.contains(filterText) || number.contains(filterText);
              final matchArea = selectedArea == null || area == selectedArea;
              final matchExcluded = !showOnlyExcluded || isExcluded;

              return matchText && matchArea && matchExcluded;
            }).toList();

            final int excludedInFilteredCount = filtered.where((c) => _excludedCases.contains(c['الرقم'].toString())).length;
            final bool allFilteredExcluded = filtered.isNotEmpty && excludedInFilteredCount == filtered.length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                          const Text('إدارة الاستثناءات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                             child: Text('${_excludedCases.length} مستثنى', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                          )
                       ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search & Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (v) => setModalState(() => filterText = v),
                          decoration: InputDecoration(
                            hintText: 'البحث بالاسم أو الرقم...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Filters Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: const Text('جميع المناطق', style: TextStyle(fontSize: 12)),
                                    value: selectedArea,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                                    items: [
                                      const DropdownMenuItem<String>(value: null, child: Text('جميع المناطق', style: TextStyle(fontSize: 12))),
                                      ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                                    ],
                                    onChanged: (val) => setModalState(() => selectedArea = val),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                               flex: 1,
                               child: GestureDetector(
                                  onTap: () => setModalState(() => showOnlyExcluded = !showOnlyExcluded),
                                  child: Container(
                                     alignment: Alignment.center,
                                     padding: const EdgeInsets.symmetric(vertical: 12),
                                     decoration: BoxDecoration(
                                        color: showOnlyExcluded ? Colors.orangeAccent.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: showOnlyExcluded ? Colors.orangeAccent : Colors.transparent)
                                     ),
                                     child: Text('المستثنى فقط', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: showOnlyExcluded ? Colors.orangeAccent : const Color(0xFF64748B))),
                                  ),
                               ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mass Action Bar
                  Padding(
                     padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                     child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text('تم العثور على: ${filtered.length} أسرة', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                           if (filtered.isNotEmpty)
                             TextButton.icon(
                                onPressed: () {
                                   setModalState(() {
                                      if (allFilteredExcluded) {
                                         // Deselect all in filtered list
                                         for (var c in filtered) {
                                            _excludedCases.remove(c['الرقم'].toString());
                                         }
                                      } else {
                                         // Select all in filtered list
                                         for (var c in filtered) {
                                            _excludedCases.add(c['الرقم'].toString());
                                         }
                                      }
                                   });
                                },
                                icon: Icon(allFilteredExcluded ? Icons.deselect : Icons.select_all, size: 16),
                                label: Text(allFilteredExcluded ? 'إلغاء التحديد' : 'تحديد الكل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                   foregroundColor: allFilteredExcluded ? Colors.grey : AppColors.primaryColor,
                                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                ),
                             )
                        ],
                     ),
                  ),
                  const Divider(height: 1),

                  // List view
                  Expanded(
                    child: filtered.isEmpty 
                      ? const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final caseNum = c['الرقم'].toString();
                        final isExcluded = _excludedCases.contains(caseNum);
                        final isAllocated = _allocations.containsKey(caseNum);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                             color: isExcluded ? Colors.orangeAccent.withValues(alpha: 0.05) : Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: isExcluded ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: CheckboxListTile(
                            value: isExcluded,
                            activeColor: Colors.orangeAccent,
                            enabled: !isAllocated,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            title: Text(c['الاسم']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isAllocated ? Colors.grey : const Color(0xFF1E293B))),
                            subtitle: Padding(
                               padding: const EdgeInsets.only(top: 4),
                               child: Text(isAllocated ? '⚠️ تم التسليم مسبقاً ولا يمكن استثناؤه' : 'رقم: $caseNum • ${c['عدد الأفراد']} أفراد • ${c['المنطقة'] ?? ''}', style: TextStyle(fontSize: 11, color: isAllocated ? Colors.orange : Colors.grey[600])),
                            ),
                            onChanged: isAllocated ? null : (val) {
                              setModalState(() {
                                if (val == true) {
                                  _excludedCases.add(caseNum);
                                } else {
                                  _excludedCases.remove(caseNum);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Save Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                       color: Colors.white,
                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _saveExcludedCases();
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('حفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final casesState = context.read<CasesCubit>().state;
      if (casesState is! CasesLoaded) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البيانات غير جاهزة للتصدير')));
         return;
      }

      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet()!;
      final sheet = excel[sheetName];
      
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final dataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'م',
        'رقم الأسرة',
        'الاسم',
        'عدد الأفراد',
        'المنطقة',
        'الوسيط',
        'حالة التسليم',
        'الكمية (كجم)'
      ];
      sheet.appendRow(headers);

      for (int i = 0; i < headers.length; i++) {
         sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      final cases = casesState.cases;
      for (int i = 0; i < cases.length; i++) {
        final c = cases[i];
        final caseNum = c['الرقم'].toString();
        final isAllocated = _allocations.containsKey(caseNum);
        final weight = isAllocated ? _allocations[caseNum]! : 0.0;

        sheet.appendRow([
          (i + 1).toString(),
          caseNum,
          c['الاسم']?.toString() ?? '',
          c['عدد الأفراد']?.toString() ?? '',
          c['المنطقة']?.toString() ?? 'غير محدد',
          c['الوسيط']?.toString() ?? 'غير محدد',
          isAllocated ? 'استلم' : 'لم يستلم',
          weight.toString(),
        ]);

        for (int col = 0; col < headers.length; col++) {
           sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: i + 1)).cellStyle = dataStyle;
        }
      }

      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/تقرير_توزيع_لحوم.xlsx');
      final fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'تقرير توزيع مشروع: ${widget.campaign.title}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التصدير: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        title: Text(widget.campaign.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            onPressed: _showExcludedFamiliesSheet,
            icon: const Icon(Icons.person_off_rounded, color: Colors.orangeAccent),
            tooltip: 'استثناء أسر',
          ),
          IconButton(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.download_rounded, color: AppColors.primaryColor),
            tooltip: 'تصدير للإكسيل',
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getAllocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _allocations = {
               for (var doc in snapshot.data!.docs)
                  doc.id: (doc.get('weight') as num).toDouble()
            };
          }

          return BlocBuilder<CasesCubit, CasesState>(
            builder: (context, casesState) {
              if (casesState is! CasesLoaded) {
                 return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
              }

              final cases = casesState.cases.where((c) {
                 final name = c['الاسم']?.toString() ?? '';
                 final num = c['الرقم']?.toString() ?? '';
                 final area = c['المنطقة']?.toString().trim() ?? '';
                 
                 final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || num.contains(_searchQuery);
                 final matchesArea = _selectedArea == null || area == _selectedArea;
                 
                 return matchesSearch && matchesArea;
              }).toList();

              final unallocatedCases = cases.where((c) {
                final cn = c['الرقم'].toString();
                return !_allocations.containsKey(cn) && !_excludedCases.contains(cn);
              }).toList();
              final allocatedCases = cases.where((c) => _allocations.containsKey(c['الرقم'].toString())).toList();

              return Column(
                children: [
                   _buildProgressHeader(),
                   _buildFiltersRow(casesState.cases),
                   Expanded(
                     child: DefaultTabController(
                       length: 2,
                       child: Column(
                         children: [
                           Container(
                             margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(30),
                               boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                             ),
                             child: TabBar(
                               dividerColor: Colors.transparent,
                               labelColor: Colors.white,
                               unselectedLabelColor: const Color(0xFF64748B),
                               indicatorSize: TabBarIndicatorSize.tab,
                               indicator: BoxDecoration(
                                 color: AppColors.primaryColor,
                                 borderRadius: BorderRadius.circular(30),
                                 boxShadow: [BoxShadow(color: AppColors.primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                               ),
                               padding: const EdgeInsets.all(4),
                               labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                               tabs: const [
                                 Tab(
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       Icon(Icons.pending_actions, size: 18),
                                       SizedBox(width: 8),
                                       Text('قيد الانتظار', style: TextStyle(fontWeight: FontWeight.bold)),
                                     ],
                                   ),
                                 ),
                                 Tab(
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                       Icon(Icons.check_circle_outline, size: 18),
                                       SizedBox(width: 8),
                                       Text('تم التسليم', style: TextStyle(fontWeight: FontWeight.bold)),
                                     ],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           Expanded(
                             child: TabBarView(
                               children: [
                                  // Tab 1: Unallocated
                                  _buildCasesList(unallocatedCases, isAllocated: false),
                                  // Tab 2: Allocated
                                  _buildCasesList(allocatedCases, isAllocated: true),
                               ],
                             )
                           ),
                         ],
                       ),
                     )
                   ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
     final remaining = widget.campaign.weightAfter - _totalDistributed;
     final progress = widget.campaign.weightAfter > 0 
           ? (_totalDistributed / widget.campaign.weightAfter).clamp(0.0, 1.0)
           : 0.0;
     final isLowStock = remaining > 0 && remaining <= 5.0;

     return Container(
       margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         gradient: LinearGradient(
           colors: isLowStock 
                ? [Colors.redAccent, Colors.orangeAccent] 
                : [AppColors.primaryColor, const Color(0xFF66A2F9)],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         borderRadius: BorderRadius.circular(24),
         boxShadow: [
           BoxShadow(
             color: (isLowStock ? Colors.orange : AppColors.primaryColor).withValues(alpha: 0.3), 
             blurRadius: 15, 
             offset: const Offset(0, 8),
           )
         ],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
             if (isLowStock)
                Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Row(
                     children: [
                       const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                       const SizedBox(width: 4),
                       const Text('تنبيه: أوشكت الكمية على النفاد!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                     ]
                   )
                ),
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي الموزع', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${_totalDistributed.toStringAsFixed(1)} كجم', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'DIN')),
                ],
             ),
             const SizedBox(height: 16),
             ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: LinearProgressIndicator(
                 value: progress, 
                 minHeight: 8, 
                 backgroundColor: Colors.black.withValues(alpha: 0.1), 
                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
               ),
             ),
             const SizedBox(height: 16),
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   _buildStatMini('الكمية المتبقية', '${remaining.toStringAsFixed(1)} كجم', Icons.scale_outlined),
                   _buildStatMini('استلموا حصتهم', '${_allocations.length} أسرة', Icons.family_restroom_rounded),
                ],
             ),
         ],
       ),
     );
  }

  Widget _buildFiltersRow(List<Map<String, dynamic>> allCases) {
    // Extract unique areas
    final Set<String> areas = {};
    for (var c in allCases) {
       final ar = c['المنطقة']?.toString().trim();
       if (ar != null && ar.isNotEmpty) areas.add(ar);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'بحث بالاسم...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: AppColors.primaryColor, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12)
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
              ),
              child: DropdownButtonHideUnderline(
                 child: DropdownButton<String>(
                   isExpanded: true,
                   hint: const Text('المنطقة', style: TextStyle(fontSize: 12)),
                   value: _selectedArea,
                   icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                   items: [
                     const DropdownMenuItem<String>(value: null, child: Text('الكل', style: TextStyle(fontSize: 12))),
                     ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))
                   ],
                   onChanged: (val) => setState(() => _selectedArea = val),
                 )
              )
            ),
          )
        ],
      )
    );
  }

  Widget _buildStatMini(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCasesList(List<Map<String, dynamic>> cases, {required bool isAllocated}) {
     if (cases.isEmpty) {
       return Center(child: Text(isAllocated ? 'لم يتم تسليم أي أسرة بعد' : 'تم تسليم جميع الأسر! 🎉', style: const TextStyle(color: Colors.grey)));
     }

     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: cases.length,
       separatorBuilder: (_, __) => const SizedBox(height: 12),
       itemBuilder: (context, index) {
          final caseItem = cases[index];
          final caseNum = caseItem['الرقم'].toString();
          final membersCount = int.tryParse(caseItem['عدد الأفراد'].toString()) ?? 1;
          
          if (!isAllocated && !_stepperValues.containsKey(caseNum)) {
             // Smart Suggestion: Dynamic share per person configured in campaign
             _stepperValues[caseNum] = membersCount * widget.campaign.sharePerPerson;
          }

          final allocatedWeight = _allocations[caseNum] ?? 0.0;
          final currentStepper = _stepperValues[caseNum] ?? widget.campaign.sharePerPerson;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isAllocated ? AppColors.primaryColor.withValues(alpha: 0.3) : Colors.transparent),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
               children: [
                 // Info
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(caseItem['الاسم'] ?? 'غير معروف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                            const Icon(Icons.people, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text('$membersCount أفراد', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.pin_drop, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Flexible(child: Text(caseItem['المنطقة']?.toString() ?? 'غير محدد', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis)),
                         ],
                       )
                     ],
                   ),
                 ),
                 // Actions
                 if (isAllocated) ...[
                     Column(
                      children: [
                         Text('$allocatedWeight كجم', style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                         TextButton.icon(
                            onPressed: () => _confirmRemoveAllocation(context, caseNum, caseItem['الاسم']?.toString() ?? 'غير معروف'), 
                            icon: const Icon(Icons.undo, size: 16, color: Colors.redAccent),
                            label: const Text('تراجع', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                         )
                      ],
                    )
                 ] else ...[
                    Column(
                      children: [
                        Row(
                          children: [
                             _StepperBtn(icon: Icons.remove, onTap: () {
                                if (currentStepper > 0.25) setState(() => _stepperValues[caseNum] = currentStepper - 0.25);
                             }),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10),
                               constraints: const BoxConstraints(minWidth: 50),
                               child: Text('$currentStepper كجم', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                             ),
                             _StepperBtn(icon: Icons.add, onTap: () {
                                setState(() => _stepperValues[caseNum] = currentStepper + 0.25);
                             }),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _allocateMeat(caseItem, currentStepper),
                          style: ElevatedButton.styleFrom(
                             backgroundColor: AppColors.primaryColor,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                             minimumSize: const Size(100, 35)
                          ),
                          child: const Text('تسليم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                 ]
               ],
            ),
          );
       },
     );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: const Color(0xFF334155)),
      ),
    );
  }
}

