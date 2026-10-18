import 'package:flutter/material.dart';

/// The eight error states Stardy can show.
enum StardyErrorType {
  forbidden,
  notFound,
  noConnection,
  serverError,
  rateLimited,
  sessionExpired,
  accountUnavailable,
  generic,
}

/// Copy, icon and labels for one error state.
///
/// In [headline], wrap the word(s) that get the red highlight in `*asterisks*`,
/// e.g. `WE *LOST* THIS PAGE`.
class StardyErrorContent {
  const StardyErrorContent({
    required this.headline,
    required this.body,
    required this.icon,
    required this.footerLabel,
    required this.primaryLabel,
    this.code,
    this.secondaryLabel,
  });

  final String headline;
  final String body;
  final IconData icon;
  final String footerLabel;
  final String primaryLabel;
  final String? secondaryLabel;

  /// Shown in the hero block (and the top bar) for HTTP-style errors.
  final String? code;

  static const Map<StardyErrorType, StardyErrorContent> all = {
    StardyErrorType.forbidden: StardyErrorContent(
      code: '403',
      icon: Icons.lock_outline,
      headline: "THIS ONE'S *OFF LIMITS*",
      body:
          "Your account doesn't have access to this page. Wrong account? Switch and try again.",
      footerLabel: 'FORBIDDEN',
      primaryLabel: 'Go home',
      secondaryLabel: 'Switch account',
    ),
    StardyErrorType.notFound: StardyErrorContent(
      code: '404',
      icon: Icons.explore_outlined,
      headline: 'WE *LOST* THIS PAGE',
      body:
          "The link is broken or the page moved. Let's get you back to learning.",
      footerLabel: 'PAGE NOT FOUND',
      primaryLabel: 'Go home',
      secondaryLabel: 'Go back',
    ),
    StardyErrorType.noConnection: StardyErrorContent(
      icon: Icons.wifi_off_rounded,
      headline: "YOU'RE *OFFLINE*",
      body:
          "Check your Wi-Fi or mobile data. We'll reconnect the moment you're back.",
      footerLabel: 'NO CONNECTION',
      primaryLabel: 'Try again',
    ),
    StardyErrorType.serverError: StardyErrorContent(
      icon: Icons.dns_outlined,
      headline: "THAT'S *ON US*",
      body:
          "Something broke on our end and we're fixing it. Try again in a minute.",
      footerLabel: 'SERVER PROBLEM',
      primaryLabel: 'Try again',
      secondaryLabel: 'Go home',
    ),
    StardyErrorType.rateLimited: StardyErrorContent(
      icon: Icons.hourglass_empty_rounded,
      headline: '*SLOW* DOWN',
      body:
          'That was a lot of requests, fast. Take a breath and try again in a moment.',
      footerLabel: 'RATE LIMITED',
      primaryLabel: 'Try again',
      secondaryLabel: 'Go home',
    ),
    StardyErrorType.sessionExpired: StardyErrorContent(
      icon: Icons.lock_clock_outlined,
      headline: '*WELCOME* BACK',
      body:
          'We signed you out to keep your account safe. Sign in to pick up where you left off.',
      footerLabel: 'SESSION EXPIRED',
      primaryLabel: 'Sign in',
      secondaryLabel: 'Go home',
    ),
    StardyErrorType.accountUnavailable: StardyErrorContent(
      icon: Icons.person_off_outlined,
      headline: 'ACCOUNT *UNAVAILABLE*',
      body: "We can't open this account right now. Tell us and we'll sort it out.",
      footerLabel: 'ACCOUNT UNAVAILABLE',
      primaryLabel: 'Contact support',
      secondaryLabel: 'Use another account',
    ),
    StardyErrorType.generic: StardyErrorContent(
      icon: Icons.warning_amber_rounded,
      headline: 'SOMETHING *WENT WRONG*',
      body:
          "We're not sure what happened. Try again, and if it sticks, we want to know.",
      footerLabel: 'ERROR',
      primaryLabel: 'Try again',
      secondaryLabel: 'Go home',
    ),
  };
}
