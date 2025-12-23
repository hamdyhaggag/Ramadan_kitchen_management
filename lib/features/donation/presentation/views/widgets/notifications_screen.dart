import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_kitchen_management/core/networking/firestore_constants.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/models/ramadan_season_model.dart';
import 'package:ramadan_kitchen_management/features/seasons/data/services/season_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SeasonService _seasonService = SeasonService();
  RamadanSeasonModel? _activeSeason;
  bool _isAdminUser = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final season = await _seasonService.getActiveSeason();
    final admin = await _checkAdminStatus();
    if (mounted) {
      setState(() {
        _activeSeason = season;
        _isAdminUser = admin;
      });
    }
  }

  Future<bool> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['role'] == 'admin';
  }

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _seasonService.getCollection(FirestoreCollections.notifications);

  void _deleteNotification(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإشعار'),
        content: const Text('هل أنت متأكد من حذف هذا الإشعار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _notificationsCollection.doc(notificationId).delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الإشعار بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل الحذف: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('d MMM y • HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSeason == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("الإشعارات")),
        body: _buildLoadingState(),
      );
    }

    Query<Map<String, dynamic>> query = _notificationsCollection;
    if (!_activeSeason!.isMigratedToV2) {
      query = query.where('seasonId', isEqualTo: _activeSeason!.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "الإشعارات",
          style: TextStyle(color: AppColors.whiteColor),
        ),
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.whiteColor,
            ),
            onPressed: () => Navigator.pop(context)),
        shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final notifications = snapshot.data?.docs ?? [];
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              return _buildNotificationCard(
                context,
                data,
                notification.id,
                _isAdminUser,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> data,
    String notificationId,
    bool isAdmin,
  ) {
    return Dismissible(
      key: Key(notificationId),
      direction: isAdmin ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
      ),
      onDismissed: (_) => _deleteNotification(context, notificationId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['title'] ?? 'بدون عنوان',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color,
                                  ),
                            ),
                            Text(
                              _formatTimestamp(data['timestamp']),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['body'] ?? 'لا يوجد نص',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد إشعارات جديدة',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيظهر هنا أي إشعارات جديدة تتلقاها',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const ShimmerLoading(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleShimmer(diameter: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LineShimmer(width: 120),
                            LineShimmer(width: 80),
                          ],
                        ),
                        SizedBox(height: 8),
                        LineShimmer(),
                        SizedBox(height: 4),
                        LineShimmer(width: 200),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'فشل في تحميل الإشعارات',
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _loadInitialData(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

// Shimmer Loading Widgets
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          Colors.grey.shade300,
          Colors.grey.shade100,
          Colors.grey.shade300,
        ],
        stops: const [0.1, 0.5, 0.9],
        begin: const Alignment(-1.0, -0.5),
        end: const Alignment(1.0, 0.5),
      ).createShader(bounds),
      child: child,
    );
  }
}

class LineShimmer extends StatelessWidget {
  final double width;
  const LineShimmer({super.key, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class CircleShimmer extends StatelessWidget {
  final double diameter;
  const CircleShimmer({super.key, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
