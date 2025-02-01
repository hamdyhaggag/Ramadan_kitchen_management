import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../manage_cases/donation_section.dart';

part 'donation_state.dart';

class DonationCubit extends Cubit<DonationState> {
  DonationCubit() : super(DonationInitial()) {
    // Initialize with default data
    final initialData = {
      'mealImageUrl': 'https://amiraspantry.com/ramadan-meal-plan-week1/',
      'mealTitle': 'إفطار اليوم',
      'mealDescription':
          'ساعد في توفير وجبات مغذية للأسر المحتاجة خلال شهر رمضان',
      'contacts': [
        ContactPerson(
          name: 'أ/ كامل صابر',
          phoneNumber: '+201033420527',
          role: 'منسق التبرعات',
          bankAccount: '1234-5678-9012-3456',
        ),
        ContactPerson(
          name: 'أ/ أحمد أبو سرية',
          phoneNumber: '+201147117011',
          role: ' منسق التبرعات',
          bankAccount: '1234-5678-9012-3456',
        ),
      ],
    };
    emit(DonationLoaded(initialData));
  }

  void updateDonationData(Map<String, dynamic> newData) {
    emit(DonationLoaded(newData));
  }
}
