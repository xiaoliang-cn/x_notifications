import 'package:x_notifications/notifications/x_notification.dart';

class XGroupNotification {
  //'com.xl.xpassword.WORK_EMAIL'...
  final String groupKey;
  final String groupChannelId;
  final String groupChannelName;
  final String groupChannelDescription;
  final XNotification xNotification;

  XGroupNotification(
      {required this.groupKey,
      required this.groupChannelId,
      required this.groupChannelName,
      required this.groupChannelDescription,
      required this.xNotification});
}
