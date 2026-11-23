/// Zawgyi detect STUB — mirrors apps/server/src/common/text/zawgyi.ts. Flags U+1031 typed before its
/// consonant and U+1039 used as asat; input is rejected so Zawgyi never reaches Drift or the outbox.
/// Sprint 3 replaces this with the shared detect → convert pipeline.
final RegExp _zawgyiOnly = RegExp(r'(^|[\s\u104a\u104b])\u1031|\u1039(?![\u1000-\u1021])');

bool looksLikeZawgyi(String s) => _zawgyiOnly.hasMatch(s);
