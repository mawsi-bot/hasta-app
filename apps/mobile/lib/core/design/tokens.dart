// GENERATED CODE — DO NOT EDIT BY HAND.
// Source: design/hasta-ds-1.0.1.json (DS 1.0.1 v1.0.0)
// Regenerate: node tools/scripts/generate-tokens.mjs
// ignore_for_file: public_member_api_docs, constant_identifier_names

import 'package:flutter/material.dart';

/// Semantic colour tokens (tier 2). Components must use these only.
@immutable
class HastaColors extends ThemeExtension<HastaColors> {
  const HastaColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgSunken,
    required this.bgOverlay,
    required this.bgBrandSubtle,
    required this.bgBrand,
    required this.bgBrandPressed,
    required this.bgBrandDisabled,
    required this.bgDangerSubtle,
    required this.bgDatingSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.textLink,
    required this.textDanger,
    required this.iconPrimary,
    required this.iconActive,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderFocus,
    required this.accentCommunity,
    required this.accentMarket,
    required this.accentDating,
    required this.stateOnline,
    required this.stateSending,
    required this.stateRead,
    required this.stateWaiting,
  });

  /// bg.canvas — app background
  final Color bgCanvas;
  /// bg.surface — card, list row
  final Color bgSurface;
  /// bg.surfaceRaised — sheet, sticky bar
  final Color bgSurfaceRaised;
  /// bg.sunken — input field, chat bg
  final Color bgSunken;
  /// bg.overlay — modal scrim 56%/64%
  final Color bgOverlay;
  /// bg.brandSubtle — selected row, mention
  final Color bgBrandSubtle;
  /// bg.brand — PRIMARY button / brand fill — new in 1.0.1, replaces the text.link workaround (ADR-0005)
  final Color bgBrand;
  /// bg.brandPressed — pressed primary (scale .98)
  final Color bgBrandPressed;
  /// bg.brandDisabled — disabled primary
  final Color bgBrandDisabled;
  /// bg.dangerSubtle — destructive background
  final Color bgDangerSubtle;
  /// bg.datingSubtle — dating mode surface
  final Color bgDatingSubtle;
  /// text.primary — body, title
  final Color textPrimary;
  /// text.secondary — metadata, timestamp
  final Color textSecondary;
  /// text.tertiary — placeholder, disabled
  final Color textTertiary;
  /// text.onBrand — on filled brand button
  final Color textOnBrand;
  /// text.link — link, @mention
  final Color textLink;
  /// text.danger — error, delete
  final Color textDanger;
  /// icon.primary — default icon
  final Color iconPrimary;
  /// icon.active — selected tab
  final Color iconActive;
  /// border.subtle — divider
  final Color borderSubtle;
  /// border.strong — input border
  final Color borderStrong;
  /// border.focus — 2px focus ring
  final Color borderFocus;
  /// accent.community — group badge
  final Color accentCommunity;
  /// accent.market — listing / seller
  final Color accentMarket;
  /// accent.dating — dating, match — dating module MUST use this token
  final Color accentDating;
  /// state.online — presence dot
  final Color stateOnline;
  /// state.sending — clock icon (pending)
  final Color stateSending;
  /// state.read — double check read
  final Color stateRead;
  /// state.waiting — offline queue
  final Color stateWaiting;

  static const HastaColors light = HastaColors(
    bgCanvas: Color(0xFFF6F8FB),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceRaised: Color(0xFFFFFFFF),
    bgSunken: Color(0xFFEEF1F6),
    bgOverlay: Color(0x8F111827),
    bgBrandSubtle: Color(0xFFEAF1FE),
    bgBrand: Color(0xFF4C5EF6),
    bgBrandPressed: Color(0xFF3D4EE0),
    bgBrandDisabled: Color(0x66B9C2FF),
    bgDangerSubtle: Color(0xFFFDECEC),
    bgDatingSubtle: Color(0xFFFDECF1),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5B6472),
    textTertiary: Color(0xFF8A93A2),
    textOnBrand: Color(0xFFFFFFFF),
    textLink: Color(0xFF2F6FED),
    textDanger: Color(0xFFE5484D),
    iconPrimary: Color(0xFF1B2432),
    iconActive: Color(0xFF2F6FED),
    borderSubtle: Color(0xFFE2E7EF),
    borderStrong: Color(0xFFCBD3DF),
    borderFocus: Color(0xFF2F6FED),
    accentCommunity: Color(0xFF1FA971),
    accentMarket: Color(0xFFF2A33C),
    accentDating: Color(0xFFEF4B7B),
    stateOnline: Color(0xFF1FA971),
    stateSending: Color(0xFF8A93A2),
    stateRead: Color(0xFF2F6FED),
    stateWaiting: Color(0xFFE0A500),
  );

  static const HastaColors dark = HastaColors(
    bgCanvas: Color(0xFF0E1621),
    bgSurface: Color(0xFF16202C),
    bgSurfaceRaised: Color(0xFF1E2A38),
    bgSunken: Color(0xFF0A1219),
    bgOverlay: Color(0xA3000000),
    bgBrandSubtle: Color(0xFF16243D),
    bgBrand: Color(0xFF4C8DFF),
    bgBrandPressed: Color(0xFF7C8BFF),
    bgBrandDisabled: Color(0x664C8DFF),
    bgDangerSubtle: Color(0xFF2A1518),
    bgDatingSubtle: Color(0xFF2A1620),
    textPrimary: Color(0xFFE8EDF4),
    textSecondary: Color(0xFF9DA9BA),
    textTertiary: Color(0xFF6E7A8B),
    textOnBrand: Color(0xFF0B1220),
    textLink: Color(0xFF4C8DFF),
    textDanger: Color(0xFFFF6B70),
    iconPrimary: Color(0xFFC9D3E0),
    iconActive: Color(0xFF4C8DFF),
    borderSubtle: Color(0xFF243141),
    borderStrong: Color(0xFF33445A),
    borderFocus: Color(0xFF4C8DFF),
    accentCommunity: Color(0xFF2FBF83),
    accentMarket: Color(0xFFF2A33C),
    accentDating: Color(0xFFFF6B93),
    stateOnline: Color(0xFF2FBF83),
    stateSending: Color(0xFF6E7A8B),
    stateRead: Color(0xFF4C8DFF),
    stateWaiting: Color(0xFFE0A500),
  );

  static const HastaColors amoled = HastaColors(
    bgCanvas: Color(0xFF000000),
    bgSurface: Color(0xFF0B0B0B),
    bgSurfaceRaised: Color(0xFF111111),
    bgSunken: Color(0xFF000000),
    bgOverlay: Color(0xA3000000),
    bgBrandSubtle: Color(0xFF16243D),
    bgBrand: Color(0xFF4C8DFF),
    bgBrandPressed: Color(0xFF7C8BFF),
    bgBrandDisabled: Color(0x664C8DFF),
    bgDangerSubtle: Color(0xFF2A1518),
    bgDatingSubtle: Color(0xFF2A1620),
    textPrimary: Color(0xFFE8EDF4),
    textSecondary: Color(0xFF9DA9BA),
    textTertiary: Color(0xFF6E7A8B),
    textOnBrand: Color(0xFF0B1220),
    textLink: Color(0xFF4C8DFF),
    textDanger: Color(0xFFFF6B70),
    iconPrimary: Color(0xFFC9D3E0),
    iconActive: Color(0xFF4C8DFF),
    borderSubtle: Color(0xFF243141),
    borderStrong: Color(0xFF33445A),
    borderFocus: Color(0xFF4C8DFF),
    accentCommunity: Color(0xFF2FBF83),
    accentMarket: Color(0xFFF2A33C),
    accentDating: Color(0xFFFF6B93),
    stateOnline: Color(0xFF2FBF83),
    stateSending: Color(0xFF6E7A8B),
    stateRead: Color(0xFF4C8DFF),
    stateWaiting: Color(0xFFE0A500),
  );

  @override
  HastaColors copyWith() => this;

  @override
  HastaColors lerp(ThemeExtension<HastaColors>? other, double t) {
    if (other is! HastaColors) return this;
    return HastaColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceRaised: Color.lerp(bgSurfaceRaised, other.bgSurfaceRaised, t)!,
      bgSunken: Color.lerp(bgSunken, other.bgSunken, t)!,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t)!,
      bgBrandSubtle: Color.lerp(bgBrandSubtle, other.bgBrandSubtle, t)!,
      bgBrand: Color.lerp(bgBrand, other.bgBrand, t)!,
      bgBrandPressed: Color.lerp(bgBrandPressed, other.bgBrandPressed, t)!,
      bgBrandDisabled: Color.lerp(bgBrandDisabled, other.bgBrandDisabled, t)!,
      bgDangerSubtle: Color.lerp(bgDangerSubtle, other.bgDangerSubtle, t)!,
      bgDatingSubtle: Color.lerp(bgDatingSubtle, other.bgDatingSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      textDanger: Color.lerp(textDanger, other.textDanger, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconActive: Color.lerp(iconActive, other.iconActive, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      accentCommunity: Color.lerp(accentCommunity, other.accentCommunity, t)!,
      accentMarket: Color.lerp(accentMarket, other.accentMarket, t)!,
      accentDating: Color.lerp(accentDating, other.accentDating, t)!,
      stateOnline: Color.lerp(stateOnline, other.stateOnline, t)!,
      stateSending: Color.lerp(stateSending, other.stateSending, t)!,
      stateRead: Color.lerp(stateRead, other.stateRead, t)!,
      stateWaiting: Color.lerp(stateWaiting, other.stateWaiting, t)!,
    );
  }
}

/// Type scale. Line height is clamped to the Myanmar minimum ratio
/// (1.65x) and weights to the Myanmar bold caps (600/700).
abstract final class HastaType {
  static const double myanmarMinLineHeightRatio = 1.65;
  static const String myanmarFamily = 'NotoSansMyanmar';
  static const String latinFamily = 'Inter';

  /// onboarding title, match name
  static const TextStyle display = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 28,
    height: 1.6500,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  /// screen title
  static const TextStyle h1 = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 24,
    height: 1.6500,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  /// section header
  static const TextStyle h2 = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 20,
    height: 1.6500,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  /// list primary, post author
  static const TextStyle subtitle = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 17,
    height: 1.6500,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  /// post text, message
  static const TextStyle body = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 15,
    height: 1.7333,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  /// unread chat name
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 15,
    height: 1.7333,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  /// comment, secondary
  static const TextStyle bodySm = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 14,
    height: 1.7143,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  /// timestamp, metadata
  static const TextStyle caption = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 13,
    height: 1.6923,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  /// badge count, tab label
  static const TextStyle micro = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 11,
    height: 1.6500,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );
  /// section label — NEVER uppercase
  static const TextStyle overline = TextStyle(
    fontFamily: myanmarFamily,
    fontFamilyFallback: <String>[latinFamily],
    fontSize: 12,
    height: 1.6667,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  static const double largeTextModeBodySize = 17;
}

abstract final class HastaSpace {
  static const double s0 = 0;
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s64 = 64;
  static const double screenHorizontalPadding = 16;
  static const double cardInnerPaddingFeed = 12;
  static const double cardInnerPaddingSettings = 16;
  static const double listRowVerticalPadding = 12;
  static const double avatarToText = 12;
  static const double sectionGap = 24;
}

abstract final class HastaRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double card = 16;
  static const double sheet = 20;
  static const double pill = 999;
  static const double bubble = 16;
  static const double bubbleTail = 6;
  static const double borderSubtle = 1;
  static const double borderFocus = 2;
}

abstract final class HastaMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration celebrate = Duration(milliseconds: 600);
}

abstract final class HastaSize {
  static const double buttonSm = 36;
  static const double buttonMd = 44;
  static const double buttonLg = 52;
  static const double touchTargetAndroid = 48;
  static const double touchTargetIos = 44;
  static const double contentMaxWidth = 640;
  static const int skeletonRowsMax = 6;
}
