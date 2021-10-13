import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../x_notification.dart';

///x notification model
abstract class XNotificationModel {
  Future<void> addNotification(XNotification xNotification);

  ///
  /// this is threadIdentifier for ios need , is can = null
  Future<void> addNotificationToGroup(
      String? threadIdentifier, XGroupNotification xGroupNotification);

  Future<void> removeNotification(List<String> id);

  Future<void> removeAllNotification();

  ///
  ///检索待处理的通知
  Future<List<PendingNotificationRequest>> pendingNotifications();

  ///且Android 可用
  ///检索待处理的活动
  Future<List<ActiveNotification>?> activityNotifications();

  void destroy();
}

///
///使用这个类操作通知
///本地通知工具类，绝对的无耦合度，方便移植其他项目
class XNotificationManager extends XNotificationModel {
  final NotificationsHelper notificationsHelper;

  XNotificationManager(this.notificationsHelper);

  @override
  Future<void> addNotification(XNotification xNotification) async {
    notificationsHelper.addNotifications(xNotification);
  }

  @override
  Future<void> addNotificationToGroup(
      String? threadIdentifier, XGroupNotification xGroupNotification) async {
    await notificationsHelper.addGroupingNotification(
        threadIdentifier, xGroupNotification);
  }

  @override
  Future<void> removeNotification(List<String> id) async {
    await notificationsHelper.cancelNotification(id);
  }

  @override
  Future<void> removeAllNotification() async {
    notificationsHelper.cancelAllNotification();
  }

  @override
  void destroy() {
    notificationsHelper.destroyXNotifications();
  }

  ///如果不是android设备则返回null
  @override
  Future<List<ActiveNotification>?> activityNotifications() async {
    return await notificationsHelper.activityNotifications();
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return await notificationsHelper.pendingNotifications();
  }
}
