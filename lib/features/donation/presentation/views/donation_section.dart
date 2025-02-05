import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:ramadan_kitchen_management/core/utils/app_colors.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_list_item.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/contact_person.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/meal_description.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/header_image.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/meal_title.dart';
import 'package:ramadan_kitchen_management/features/donation/presentation/views/widgets/section_title.dart';
import '../cubit/donation_cubit.dart';

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
          final carouselImages = [state.donationData['mealImageUrl']];
          return Scaffold(
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: CarouselSlider(
                    items: carouselImages.map((url) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        MealTitle(title: state.donationData['mealTitle']),
                        const SizedBox(height: 12),
                        MealDescription(
                            description: state.donationData['mealDescription']),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SectionTitle(
                              title: 'عدد الأفراد لهذا اليوم:',
                            ),
                            const SizedBox(width: 12),
                            Card(
                              color:
                                  AppColors.primaryColor.withValues(alpha: 0.1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.whiteColor,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: Text(
                                  '${state.donationData['numberOfIndividuals']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blackColor,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        HeaderImage(
                            imageUrl: state.donationData['mealImageUrl']),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DonationFormScreen(contacts: contacts),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'للتبرع',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
          ),
        );
      },
    );
  }
}

class DonationFormScreen extends StatelessWidget {
  final List<ContactPerson> contacts;

  const DonationFormScreen({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طرق التبرع'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ContactListItem(contact: contacts[index]),
                childCount: contacts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
