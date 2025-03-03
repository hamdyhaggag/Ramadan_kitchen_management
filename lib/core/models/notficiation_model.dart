class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? payload;
  NotificationModel( {
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });
}
