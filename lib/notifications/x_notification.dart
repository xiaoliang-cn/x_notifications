import 'dart:math';

final _defaultTitle = 'Xpassword';
final _defaultSubtitle = "A new Xpassword Info";

class XNotification {
  final int id;
  final String title;
  final String subtitle;
  final String? channelId;
  final String? channelName;
  final String? channelDescription;
  //深层链接，跳转
  final String uri;
  XNotification(
      {required this.title,
      required this.subtitle,
      this.uri = '',
      required this.id,
      this.channelId,
      this.channelName,
      this.channelDescription});

  factory XNotification.defaultValue(String defaultId) {
    return XNotification(
        title: _defaultTitle,
        subtitle: _defaultSubtitle,
        id: Random().nextInt(0xff));
  }
}
