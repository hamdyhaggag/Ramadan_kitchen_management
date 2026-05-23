import '../data/models/meat_campaign_model.dart';

abstract class MeatCampaignsState {}

class MeatCampaignsLoading extends MeatCampaignsState {}

class MeatCampaignsLoaded extends MeatCampaignsState {
  final List<MeatCampaign> campaigns;
  MeatCampaignsLoaded(this.campaigns);
}

class MeatCampaignsError extends MeatCampaignsState {
  final String message;
  MeatCampaignsError(this.message);
}
