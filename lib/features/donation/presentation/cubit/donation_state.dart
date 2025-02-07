part of 'donation_cubit.dart';

abstract class DonationState {}

class DonationInitial extends DonationState {}

class DonationLoaded extends DonationState {
  final List<Map<String, dynamic>> donations;
  DonationLoaded({required this.donations});
}

class DonationError extends DonationState {
  final String message;
  DonationError(this.message);
}
