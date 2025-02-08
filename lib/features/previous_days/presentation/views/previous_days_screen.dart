import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/cubit/donation_cubit.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأيام السابقة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<DonationCubit, DonationState>(
        builder: (context, state) {
          if (state is DonationLoaded) {
            final filteredDonations = state.donations.where((donation) {
              final title =
                  donation['mealTitle']?.toString().toLowerCase() ?? '';
              return title.contains(_searchQuery.trim().toLowerCase());
            }).toList();

            return Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildDonationList(filteredDonations),
                ),
              ],
            );
          } else if (state is DonationError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          hintStyle: const TextStyle(color: Colors.grey),
          hintText: 'بتدور على إفطار يوم معين ؟ .. ',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildDonationList(List<dynamic> donations) {
    if (donations.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'لا يوجد إفطارات سابقة'
              : 'لا يوجد إفطارات سابقة باسم "$_searchQuery"',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: donations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final donation = donations[index];
        final date = (donation['created_at'] as Timestamp).toDate();
        return DonationCardOfPrevious(
          date: date,
          mealTitle: donation['mealTitle'] ?? 'Untitled Meal',
          description: donation['mealDescription'] ?? '',
          participants: donation['numberOfIndividuals'] ?? 0,
          imageUrl: donation['mealImageUrl'] ?? '',
        );
      },
    );
  }
}
