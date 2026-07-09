import 'package:flutter/widgets.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../config/env.dart';

/// ZegoCloud voice/video calling (prebuilt call kit + invitations).
///
/// - [initApp] is called once at startup (sets up the system calling UI +
///   navigator key).
/// - [onUserLogin] registers the signed-in user so they can place & receive
///   call invitations; [onUserLogout] tears it down.
class CallService {
  CallService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _inited = false;

  /// Calling is available only when the Zego keys are configured in `.env`.
  static bool get enabled =>
      Env.zegoAppId != 0 && Env.zegoAppSign.isNotEmpty;

  /// ZegoCloud (ZIM) user IDs are capped at 32 chars and must be simple.
  /// Supabase UUIDs are 36 chars (with hyphens) → strip them to 32 hex chars.
  static String zegoUserId(String supabaseUserId) =>
      supabaseUserId.replaceAll('-', '');

  static Future<void> initApp() async {
    if (!enabled) return;
    await ZegoUIKit().initLog();
    ZegoUIKitPrebuiltCallInvitationService()
        .useSystemCallingUI([ZegoUIKitSignalingPlugin()]);
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  }

  static Future<void> onUserLogin(String userId, String userName) async {
    if (!enabled || _inited) return;
    _inited = true;
    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: Env.zegoAppId,
      appSign: Env.zegoAppSign,
      userID: zegoUserId(userId),
      userName: userName.trim().isEmpty ? 'User' : userName.trim(),
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  static Future<void> onUserLogout() async {
    if (!_inited) return;
    _inited = false;
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
  }
}
