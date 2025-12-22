import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/cubit/donation_cubit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ramadan_kitchen_management/core/services/service_locator.dart';
import 'package:ramadan_kitchen_management/features/auth/data/repos/auth_repo.dart';
import '../widgets/card_of_previous.dart';

class PreviousDaysScreen extends StatefulWidget {
  const PreviousDaysScreen({super.key});

  @override
  State<PreviousDaysScreen> createState() => _PreviousDaysScreenState();
}

class _PreviousDaysScreenState extends State<PreviousDaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = getIt<AuthRepo>().currentUser?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: isAdmin
          ? AppBar(
              title: const Text(
                'سجل الأيام السابقة',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DIN',
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: Colors.black,
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: BlocBuilder<DonationCubit, DonationState>(
              builder: (context, state) {
                if (state is DonationLoaded) {
                  final filteredDonations = state.donations.where((donation) {
                    final query = _searchQuery.trim().toLowerCase();
                    final title =
                        donation['mealTitle']?.toString().toLowerCase() ?? '';
                    final description =
                        donation['mealDescription']?.toString().toLowerCase() ??
                            '';
                    return title.contains(query) || description.contains(query);
                  }).toList();

                  if (filteredDonations.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildDonationList(filteredDonations);
                } else if (state is DonationError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.danger, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'ابحث عن وجبة أو تاريخ معين...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Iconsax.search_normal_1,
                color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle5, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDonationList(List<dynamic> donations) {
    return AnimationLimiter(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        itemCount: donations.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final donation = donations[index];
          final date = (donation['created_at'] as Timestamp).toDate();

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: DonationCardOfPrevious(
                  date: date,
                  mealTitle: donation['mealTitle'] ?? 'بدون عنوان',
                  description: donation['mealDescription'] ?? '',
                  participants: donation['numberOfIndividuals'] ?? 0,
                  imageUrl: donation['mealImageUrl'] ?? '',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              _searchQuery.isEmpty
                  ? Iconsax.calendar_remove
                  : Iconsax.search_status,
              size: 60,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'لا توجد بيانات سابقة حتى الآن'
                : 'لم يتم العثور على نتائج',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              fontFamily: 'DIN',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'سيتم عرض الوجبات التي يتم انتهاؤها هنا'
                : 'جرب البحث بكلمات أخرى',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
