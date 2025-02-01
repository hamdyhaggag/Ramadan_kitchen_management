part of 'donation_cubit.dart';

abstract class DonationState {}

class DonationInitial extends DonationState {}

class DonationLoaded extends DonationState {
  final Map<String, dynamic> donationData;
  final String documentId;

  DonationLoaded({
    required this.donationData,
    required this.documentId,
  });
}

class DonationError extends DonationState {
  final String message;

  DonationError(this.message);
}
