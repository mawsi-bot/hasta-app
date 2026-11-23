import 'package:flutter/foundation.dart';

import '../../../core/network/api_failure.dart';

@immutable
class AccountSummary {
  const AccountSummary({required this.id, required this.isGuest, required this.status});
  final String id;
  final bool isGuest;
  final String status;
}

enum AuthPhase { booting, signedOut, signingIn, signedIn }

/// Why the Welcome CTA could not complete.
sealed class WelcomeIssue {
  const WelcomeIssue();

  static WelcomeIssue fromFailure(ApiFailure f) => switch (f.code) {
        'device_cooldown' => CooldownIssue(f.retryAfterDays ?? 1),
        'feature_disabled' => const GuestDisabledIssue(),
        'rate_limited' => const RateLimitedIssue(),
        _ => FailureIssue(f.displayCode),
      };
}

/// T42 — remaining cooldown days from `details.retry_after_days`.
class CooldownIssue extends WelcomeIssue {
  const CooldownIssue(this.days);
  final int days;
}

class GuestDisabledIssue extends WelcomeIssue {
  const GuestDisabledIssue();
}

class RateLimitedIssue extends WelcomeIssue {
  const RateLimitedIssue();
}

class FailureIssue extends WelcomeIssue {
  const FailureIssue(this.code);
  final String code;
}

@immutable
class AuthState {
  const AuthState._(this.phase, {this.account, this.issue});

  const AuthState.booting() : this._(AuthPhase.booting);
  const AuthState.signedOut({WelcomeIssue? issue}) : this._(AuthPhase.signedOut, issue: issue);
  const AuthState.signingIn() : this._(AuthPhase.signingIn);
  const AuthState.signedIn(AccountSummary account) : this._(AuthPhase.signedIn, account: account);

  final AuthPhase phase;
  final AccountSummary? account;
  final WelcomeIssue? issue;
}
