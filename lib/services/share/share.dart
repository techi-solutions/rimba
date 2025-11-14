import 'dart:ui';
import 'package:share_plus/share_plus.dart';

/// Service for sharing content using the native share sheet
/// Wraps the share_plus plugin to provide a consistent interface
class SharingService {
  // Singleton pattern
  static final SharingService _instance = SharingService._internal();
  
  factory SharingService() {
    return _instance;
  }
  
  SharingService._internal();

  /// Share a group join link with a custom message
  /// 
  /// [groupName] - Name of the group to share
  /// [groupId] - ID of the group
  /// [link] - The complete deeplink URL to share
  /// [sharePositionOrigin] - Position for iPad popover (optional)
  /// 
  /// Returns a ShareResult indicating if the share was successful
  Future<ShareResult> shareGroupLink(
    String groupName,
    String groupId, {
    required String link,
    Rect? sharePositionOrigin,
  }) async {
    final shareText = '''Join my group "$groupName" on Rimba! 🎉

$link

Tap the link to join the group and start contributing together.''';

    return Share.share(
      shareText,
      subject: 'Join "$groupName" on Rimba',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share a simple text message
  /// 
  /// [text] - The text to share
  /// [subject] - Optional subject line
  /// [sharePositionOrigin] - Position for iPad popover (optional)
  Future<ShareResult> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    return Share.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

