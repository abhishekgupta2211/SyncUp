import 'package:flutter/material.dart';

/// App-wide constants and feature flags.
class AppConfig {
  AppConfig._();

  static const String appName = 'RevvRide';
  static const String tagline = 'Born to Ride. Built to Connect.';

  /// flutter_screenutil design canvas (iPhone-13 logical size).
  static const Size designSize = Size(375, 812);

  /// Voice/video calling via ZegoCloud. Active when the Zego keys are present
  /// in `.env` (see [CallService.enabled]).
  static const bool callsEnabled = true;
}
