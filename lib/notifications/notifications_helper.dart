import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:x_notifications/notifications/x_notification.dart';

import 'x_group_notification.dart';

class NotificationsHelper {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _defaultAppIcon = 'assets/appLogo.png';

  //回调 一般用于ios
  final List<DidReceiveLocalNotificationCallback>
      _listDidReceiverLocalNotificationCallbacks = [];

  //回调
  final List<SelectNotificationCallback> _listSelectNotificationCallbacks = [];
  final BuildContext context;

  NotificationsHelper.init(this.context, {String? initAppIcon}) {
    _initNotificationPlugin(initAppIcon);
  }

  set setDidReceiverLocalNotificationCallback(
          DidReceiveLocalNotificationCallback callback) =>
      _listDidReceiverLocalNotificationCallbacks.add(callback);

  set setSelectNotificationCallback(SelectNotificationCallback callback) =>
      _listSelectNotificationCallbacks.add(callback);

  //初始化
  Future<void> _initNotificationPlugin(String? initAppIcon) async {
    //初始化时区数据库
    tz.initializeTimeZones();
    initAppIcon ??= _defaultAppIcon;
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(initAppIcon);
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            requestSoundPermission: false,
            requestBadgePermission: false,
            requestAlertPermission: false,
            onDidReceiveLocalNotification: _iosNotificationsCall);
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onselectNotification);
    _iosRequestPermissions();
  }

  ///
  ///检索待处理的通知
  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pendingNotificationRequests;
  }

  ///
  ///检索待处理的活动
  Future<List<ActiveNotification>?> activityNotifications() async {
    if (!Platform.isAndroid) return null;
    final List<ActiveNotification>? activeNotifications =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.getActiveNotifications();
    return activeNotifications;
  }

  Future<void> addGroupingNotification(
      String? threadIdentifier, XGroupNotification xGroupNotification) async {
    if (Platform.isAndroid) {
      _createAndroidGroupingNotification(xGroupNotification);
    } else if (Platform.isIOS || Platform.isMacOS) {
      _createIOSGroupingNotification(threadIdentifier, xGroupNotification);
    }
  }

  //分组通知 IOS
  Future<void> _createIOSGroupingNotification(
      String? threadIdentifier, XGroupNotification xGroupNotification) async {
    threadIdentifier ??= 'xpassword';
    IOSNotificationDetails iOSPlatformChannelSpecifics =
        IOSNotificationDetails(threadIdentifier: threadIdentifier);
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            xGroupNotification.xNotification.channelId == null
                ? "xpassword"
                : xGroupNotification.xNotification.channelId!,
            xGroupNotification.xNotification.channelName == null
                ? "xpasswordName"
                : xGroupNotification.xNotification.channelName!,
            channelDescription:
                xGroupNotification.xNotification.channelDescription,
            importance: Importance.max,
            priority: Priority.high,

            /// Specifies the "ticker" text which is sent to accessibility services.
            ticker: 'ticker');
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(
        0,
        xGroupNotification.xNotification.title,
        xGroupNotification.xNotification.subtitle,
        platformChannelSpecifics,
        payload: xGroupNotification.xNotification.title);
  }

  //android grouping notification
  Future<void> _createAndroidGroupingNotification(
      XGroupNotification xGroupNotification) async {
    //参数例子
    // const String groupKey = 'com.xl.xpassword.WORK_EMAIL';
    // const String groupChannelId = 'grouped channel id';
    // const String groupChannelName = 'grouped channel name';
    // const String groupChannelDescription = 'grouped channel description';
// example based on https://developer.android.com/training/notify-user/group.html

    AndroidNotificationDetails firstNotificationAndroidSpecifics =
        AndroidNotificationDetails(xGroupNotification.groupChannelId,
            xGroupNotification.groupChannelName,
            channelDescription: xGroupNotification.groupChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            groupKey: xGroupNotification.groupKey);
    NotificationDetails firstNotificationPlatformSpecifics =
        NotificationDetails(android: firstNotificationAndroidSpecifics);
    flutterLocalNotificationsPlugin.show(
        xGroupNotification.xNotification.id,
        xGroupNotification.xNotification.title,
        xGroupNotification.xNotification.subtitle,
        firstNotificationPlatformSpecifics);
    // Create the summary notification to support older devices that pre-date
    /// Android 7.0 (API level 24).
    ///
    /// Recommended to create this regardless as the behaviour may vary as
    /// mentioned in https://developer.android.com/training/notify-user/group
    const List<String> lines = <String>[
      'Alex Faarborg  Check this out',
      'Jeff Chang    Launch Party'
    ];
    const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
        lines,
        contentTitle: '2 messages',
        summaryText: 'janedoe@example.com');
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(xGroupNotification.groupChannelId,
            xGroupNotification.groupChannelName,
            channelDescription: xGroupNotification.groupChannelDescription,
            styleInformation: inboxStyleInformation,
            groupKey: xGroupNotification.groupKey,
            setAsGroupSummary: true);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        3, 'Attention', 'Two messages', platformChannelSpecifics);
  }

  ///   Scheduling a notification  指定时间运行通知
  ///```
  ///   AndroidNotificationDetails androidPlatformChannelSpecifics =
  ///   AndroidNotificationDetails(
  ///      'repeating channel id', 'repeating channel name',
  ///       channelDescription: 'repeating description');
  ///       const NotificationDetails platformChannelSpecifics =
  ///       NotificationDetails(android: androidPlatformChannelSpecifics);
  ///   await flutterLocalNotificationsPlugin.periodicallyShow(0, 'repeating title',
  ///  'repeating body', RepeatInterval.everyMinute, platformChannelSpecifics,
  ///  androidAllowWhileIdle: true);
  ///
  ///```
  _showSchedulingNotification(
      XNotification notification, Duration addTime) async {
    //获取当前时区
    final String currentTimeZone =
        await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    // ------------------
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notification.id,
      notification.title,
      notification.subtitle,
      tz.TZDateTime.now(tz.local).add(addTime),
      NotificationDetails(
          android: AndroidNotificationDetails(
              notification.channelId == null
                  ? 'xpassword_scheduled'
                  : notification.channelId!,
              notification.channelName == null
                  ? 'scheduled'
                  : notification.channelName!,
              channelDescription: 'timer notification')),
      //在 Android 上，androidAllowWhileIdle用于确定即使设备处于低功耗空闲模式时，是否也应在指定时间传递通知。
      androidAllowWhileIdle: true,
      //在uiLocalNotificationDateInterpretation被要求作为比上年长10作为时区支持是有限的iOS版本。这意味着不可能为另一个时区安排通知，
      //也无法让 iOS 调整在夏令时发生时通知出现的时间。
      //使用此参数，它用于确定是否应将预定日期解释为绝对时间或挂钟时间。
      //
      //有一个可选matchDateTimeComponents参数可用于通过告诉插件分别匹配时间或星期几和时间的组合来安排每天或每周显示的通知。
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  //添加一个通知
  void addNotifications(XNotification notification) {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            notification.channelId == null
                ? "xpassword"
                : notification.channelId!,
            notification.channelName == null
                ? "xpasswordName"
                : notification.channelName!,
            channelDescription: notification.channelDescription,
            importance: Importance.max,
            priority: Priority.high,

            /// Specifies the "ticker" text which is sent to accessibility services.
            ticker: 'ticker');
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(notification.id, notification.title,
        notification.subtitle, platformChannelSpecifics,
        payload: notification.title);
  }

  //请求权限IOS Mac
  Future<bool?> _iosRequestPermissions() async {
    ///flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()如果应用程序在 iOS 上运行，
    ///则调用返回包含特定于 iOS 的 API 的插件的 iOS 实现。同样，
    ///macOS 实现通过调用返回flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()。
    ///使用该?.运算符是因为在其他平台上运行时结果将为空。开发人员也可以选择通过检查他们的应用程序运行的平台来保护这个调用。
    bool? result;
    if (Platform.isIOS) {
      //需要在合适的位置请求权限
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isMacOS) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    return result;
  }

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('app_icon');

  /// Signature of callback passed to [initialize] that is triggered when user
  /// taps on a notification.
  /// 有效负载可以表示您要显示其详细信息的项目的 id
  void _onselectNotification(String? paylaod) {}

  //ios 通知回调被触发
  _iosNotificationsCall(int id, String? title, String? body, String? payload) {
    // display a dialog with the notification details, tap ok to go to another page
    //触发所有回调
    _listDidReceiverLocalNotificationCallbacks.forEach((callback) {
      callback(id, title, body, payload);
    });
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) => CupertinoAlertDialog(
    //     title: Text(title == null ? '' : title),
    //     content: Text(body == null ? '' : body),
    //     actions: [
    //       CupertinoDialogAction(
    //         isDefaultAction: true,
    //         child: Text('Ok'),
    //         onPressed: () async {
    //           //关闭notifications
    //           Navigator.of(context, rootNavigator: true).pop();
    //
    //           // await Navigator.push(
    //           //   context,
    //           //   MaterialPageRoute(
    //           //     builder: (context) => HomePage(),
    //           //   ),
    //           // );
    //         },
    //       )
    //     ],
    //   ),
    // );
  }

  Future cancelNotification([id]) async {
    [id].forEach((vid) async {
      await flutterLocalNotificationsPlugin.cancel(vid);
    });
  }

  Future cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  //应用退出记得销毁所有通知
  void destroyXNotifications() {
    _listDidReceiverLocalNotificationCallbacks.clear();
    _listSelectNotificationCallbacks.clear();
  }

  ///通过此插件创建的通知获取有关应用程序是否已启动的详细信息
  Future<NotificationAppLaunchDetails?> findRuningNotification() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    return notificationAppLaunchDetails;
  }
}
