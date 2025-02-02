import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_list_item.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_person.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/meal_description.dart';

import '../cubit/donation_cubit.dart';
import 'widgets/header_image.dart';
import 'widgets/meal_title.dart';
import 'widgets/section_title.dart';

class DonationSection extends StatelessWidget {
  const DonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DonationCubit, DonationState>(
      builder: (context, state) {
        if (state is DonationLoaded) {
          final contacts = (state.donationData['contacts'] as List<dynamic>)
              .map((e) => ContactPerson.fromMap(e))
              .toList();

          return Scaffold(
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight:
                      MediaQuery.of(context).size.width * (1180 / 1500),
                  flexibleSpace:
                      HeaderImage(imageUrl: state.donationData['mealImageUrl']),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        MealTitle(title: state.donationData['mealTitle']),
                        const SizedBox(height: 16),
                        MealDescription(
                            description: state.donationData['mealDescription']),
                        const SizedBox(height: 32),
                        SectionTitle(title: 'للتبرع للمطبخ'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ContactListItem(contact: contacts[index]),
                      childCount: contacts.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          );
        }
        return const Center(
            child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ));
      },
    );
  }
}
