import 'package:flutter/foundation.dart';

/// Editable profile basics (Sprint 1). Avatar upload lands in Sprint 6.
@immutable
class ProfileDraft {
  const ProfileDraft({this.displayName, this.username, this.bio, this.birthDate});

  final String? displayName;
  final String? username;
  final String? bio;

  /// ISO date `YYYY-MM-DD`.
  final String? birthDate;

  static final RegExp usernamePattern = RegExp(r'^[a-z0-9._]{3,32}$');
  static const int bioMax = 300;
  static const int displayNameMax = 64;

  Map<String, String> toWire() => <String, String>{
        if (displayName != null) 'display_name': displayName!,
        if (username != null) 'username': username!,
        if (bio != null) 'bio': bio!,
        if (birthDate != null) 'birth_date': birthDate!,
      };
}
