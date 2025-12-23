import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ramadan_kitchen_management/core/networking/firestore_constants.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/core/widgets/general_button.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/models/ramadan_season_model.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';

class ManageGroupsScreen extends StatefulWidget {
  const ManageGroupsScreen({super.key});

  @override
  State<ManageGroupsScreen> createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends State<ManageGroupsScreen> {
  List<DocumentSnapshot>? _localDocs;
  RamadanSeasonModel? _activeSeason;
  final SeasonService _seasonService = SeasonService();

  @override
  void initState() {
    super.initState();
    _loadActiveSeason();
  }

  Future<void> _loadActiveSeason() async {
    final activeSeason = await _seasonService.getActiveSeason();
    if (mounted) {
      setState(() {
        _activeSeason = activeSeason;
      });
    }
  }

  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _seasonService.getCollection(FirestoreCollections.caseGroups);

  @override
  Widget build(BuildContext context) {
    if (_activeSeason == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FE),
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor)),
      );
    }

    Query<Map<String, dynamic>> query = _groupsCollection;
    if (!_activeSeason!.isMigratedToV2) {
      query = query.where('seasonId', isEqualTo: _activeSeason!.id);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _localDocs == null) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            if (_localDocs != null && _localDocs!.isNotEmpty) {
              // Fallback to local
            } else {
              return _buildEmptyState(context);
            }
          }

          if (snapshot.hasData) {
            _localDocs = snapshot.data!.docs;
          }

          final docs = _localDocs!;
          int totalFamilies = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final list = data['caseNumbers'] as List?;
            totalFamilies += list?.length ?? 0;
          }

          return Column(
            children: [
              _buildStatsHeader(docs.length, totalFamilies),
              Expanded(
                child: AnimationLimiter(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: docs.length,
                    onReorder: _onReorder,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          return Material(
                            elevation: 12,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final groupName = data['name'] ?? doc.id;
                      final cases = List<int>.from(data['caseNumbers'] ?? []);
                      cases.sort();

                      return Container(
                        key: Key(doc.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildGroupCard(
                                  context, doc.id, groupName, cases, index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _localDocs!.removeAt(oldIndex);
      _localDocs!.insert(newIndex, item);
    });

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < _localDocs!.length; i++) {
      batch.update(_localDocs![i].reference, {'order': i});
    }
    await batch.commit();
  }

  Widget _buildStatsHeader(int totalGroups, int totalFamilies) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'إدارة المجموعات',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DIN',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showGroupDialog(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatItem('المجموعات', '$totalGroups',
                    Icons.category_rounded, Colors.white),
                const SizedBox(width: 12),
                _buildStatItem('إجمالي الأسر', '$totalFamilies',
                    Icons.people_alt_rounded, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    final isWhite = color == Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isWhite ? 0.15 : 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: isWhite ? 0.1 : 0.0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isWhite ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, color: isWhite ? Colors.white : color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isWhite ? Colors.white : Colors.black87)),
                Text(label,
                    style: TextStyle(
                        color: isWhite ? Colors.white70 : Colors.grey[600],
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, String docId, String groupName,
      List<int> cases, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showGroupDialog(context,
              docId: docId, groupName: groupName, currentCases: cases),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.drag_indicator_rounded, color: Colors.grey[300]),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.8),
                            AppColors.primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        groupName.isNotEmpty
                            ? groupName.trim().characters.first
                            : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'DIN',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${cases.length} أسرة مسجلة',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: Colors.blue,
                          onTap: () => _showGroupDialog(context,
                              docId: docId,
                              groupName: groupName,
                              currentCases: cases),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: Colors.red,
                          onTap: () =>
                              _confirmDelete(context, docId, groupName),
                        ),
                      ],
                    ),
                  ],
                ),
                if (cases.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[100], height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...cases.take(8).map((c) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              '$c',
                              style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          )),
                      if (cases.length > 8)
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('+${cases.length - 8}',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 20, color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.groups_3_rounded, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد مجموعات لهذا الموسم',
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على الزر بالأسفل لإضافة أول مجموعة',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: GeneralButton(
              text: 'إضافة مجموعة',
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
              onPressed: () => _showGroupDialog(context),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  void _showGroupDialog(BuildContext context,
      {String? docId, String? groupName, List<int>? currentCases}) {
    final nameController = TextEditingController(text: groupName);
    final casesController =
        TextEditingController(text: currentCases?.join(', ') ?? '');
    final isEditing = docId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'تعديل المجموعة' : 'مجموعة جديدة',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'اسم المجموعة',
                hintText: 'مثال: المجموعة الأولى',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: casesController,
              decoration: InputDecoration(
                labelText: 'أرقام الحالات',
                hintText: 'مثال: 1, 2, 3 أو 1-10',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك كتابة نطاقات مثل (1-10) أو أرقام فردية (1, 5, 9)',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final newName = nameController.text.trim();
              final cases = _parseCases(casesController.text);

              if (isEditing) {
                await _groupsCollection.doc(docId).update({
                  'name': newName,
                  'caseNumbers': cases,
                });
              } else {
                Query<Map<String, dynamic>> query = _groupsCollection;
                if (!_activeSeason!.isMigratedToV2) {
                  query = query.where('seasonId', isEqualTo: _activeSeason!.id);
                }

                final snapshot = await query
                    .orderBy('order', descending: true)
                    .limit(1)
                    .get();

                int newOrder = 0;
                if (snapshot.docs.isNotEmpty) {
                  newOrder = (snapshot.docs.first.data()['order'] ?? 0) + 1;
                }

                await _groupsCollection.add({
                  'name': newName,
                  'caseNumbers': cases,
                  'order': newOrder,
                  'seasonId': _activeSeason!.id,
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('حفظ التغييرات',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<int> _parseCases(String text) {
    if (text.isEmpty) return [];
    final Set<int> cases = {};
    final parts = text.split(',');

    for (var part in parts) {
      part = part.trim();
      if (part.contains('-')) {
        final range = part.split('-');
        if (range.length == 2) {
          final start = int.tryParse(range[0]);
          final end = int.tryParse(range[1]);
          if (start != null && end != null) {
            for (var i = start; i <= end; i++) {
              cases.add(i);
            }
          }
        }
      } else {
        final num = int.tryParse(part);
        if (num != null) {
          cases.add(num);
        }
      }
    }
    return cases.toList()..sort();
  }

  void _confirmDelete(BuildContext context, String docId, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف المجموعة'),
        content: Text('هل أنت متأكد من حذف المجموعة "$groupName"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await _groupsCollection.doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
