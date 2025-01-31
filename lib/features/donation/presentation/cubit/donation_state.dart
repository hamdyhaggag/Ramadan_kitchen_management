part of 'donation_cubit.dart';

abstract class DonationState {}

class DonationInitial extends DonationState {}

class DonationLoaded extends DonationState {
  final Map<String, dynamic> donationData;

  DonationLoaded(this.donationData);
}
