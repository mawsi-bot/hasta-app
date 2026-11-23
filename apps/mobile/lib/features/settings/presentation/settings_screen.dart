import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/drift/app_database.dart';
import '../../../core/design/hasta_theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/list_row.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/domain/auth_controller.dart';
import '../../linked_accounts/presentation/linked_accounts_sheet.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../profile/presentation/profile_providers.dart';

/// Settings shell — all 11 sections (SPEC §10.3). Sprint 1 wires Account →
/// Edit profile, Language and Sign out; the other rows are visible placeholders
/// filled by later sprints.
///
/// States: loading = static; error = toast; offline = local-only banner
/// ("ချိန်ညှိမှု သိမ်းမထားပါ") and online-only rows visibly disabled with a
/// reason — Connect Gmail is the T43 case.
/// Drift-backed so the Premium row updates as soon as link:complete flips `is_guest` (T44 client half).
final StreamProvider<LocalAccount?> localAccountProvider = StreamProvider<LocalAccount?>((Ref ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return db.select(db.localAccounts).watchSingleOrNull();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Key connectGmailKey = Key('settings-connect-gmail');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool online = ref.isOnline;
    final String lang = ref.watch(localeProvider).valueOrNull?.languageCode ?? 'my';
    final LocalProfile? profile = ref.watch(myProfileProvider).valueOrNull;
    final bool isGuest = ref.watch(localAccountProvider).valueOrNull?.isGuest ?? true;

    void soon() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.comingSoon)));
    HastaListRow placeholder(String title, IconData icon) =>
        HastaListRow(title: title, subtitle: l.comingSoon, icon: icon, onTap: soon);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: Column(
        children: <Widget>[
          if (!online) OfflineBanner(message: '${l.offlineBanner} ${l.settingsOfflineLocalOnly}'),
          Expanded(
            child: ListView(
              key: const Key('settings-list'),
              children: <Widget>[
                SectionHeader(l.settingsAccount),
                HastaListRow(
                  key: const Key('settings-edit-profile'),
                  title: l.settingsEditProfile,
                  icon: Icons.edit_outlined,
                  enabled: profile != null,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => EditProfileScreen(initial: profile!))),
                ),
                HastaListRow(
                  key: connectGmailKey,
                  title: l.settingsConnectGmail,
                  subtitle: online ? l.settingsLinkedAccounts : l.settingsOnlineOnly,
                  icon: Icons.mail_outline,
                  enabled: online,
                  onTap: () => showLinkedAccountsSheet(context),
                ),
                HastaListRow(
                  title: l.settingsChangeDevice,
                  subtitle: online ? l.comingSoon : l.settingsOnlineOnly,
                  icon: Icons.qr_code_2,
                  enabled: online,
                  onTap: soon,
                ),
                SectionHeader(l.settingsPrivacySecurity),
                placeholder(l.settingsActiveSessions, Icons.devices_other_outlined),
                SectionHeader(l.settingsNotifications),
                placeholder(l.settingsNotifications, Icons.notifications_none),
                SectionHeader(l.settingsDataStorage),
                placeholder(l.settingsDataStorage, Icons.storage_outlined),
                SectionHeader(l.settingsChat),
                placeholder(l.settingsChat, Icons.chat_bubble_outline),
                SectionHeader(l.settingsAppearance),
                placeholder(l.settingsAppearance, Icons.palette_outlined),
                SectionHeader(l.settingsDating),
                placeholder(l.settingsDating, Icons.favorite_border),
                SectionHeader(l.settingsDevices),
                placeholder(l.settingsDevices, Icons.phone_android),
                SectionHeader(l.settingsLanguage),
                _LanguageRow(code: 'my', label: l.languageMyanmar, selected: lang == 'my'),
                _LanguageRow(code: 'en', label: l.languageEnglish, selected: lang == 'en'),
                SectionHeader(l.settingsPremium),
                HastaListRow(
                    title: l.settingsPremium, subtitle: isGuest ? l.premiumGuestBlocked : l.comingSoon, icon: Icons.workspace_premium_outlined, onTap: soon),
                SectionHeader(l.settingsHelp),
                placeholder(l.welcomePrivacyTerms, Icons.help_outline),
                const SizedBox(height: HastaSpace.sectionGap),
                HastaListRow(
                  key: const Key('settings-sign-out'),
                  title: l.settingsSignOut,
                  icon: Icons.logout,
                  destructive: true,
                  onTap: () => _confirmSignOut(context, ref, l),
                ),
                const SizedBox(height: HastaSpace.s48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, AppLocalizations l) async {
    final HastaColors c = context.colors;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.settingsSignOutTitle),
        content: Text(l.settingsSignOutBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          // Destructive action on the right, verb only (DS copy rule).
          TextButton(
            key: const Key('confirm-sign-out'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.settingsSignOutAction, style: TextStyle(color: c.textDanger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    await ref.read(authControllerProvider.notifier).signOut();
  }
}

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow({required this.code, required this.label, required this.selected});
  final String code;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HastaColors c = context.colors;
    return HastaListRow(
      key: Key('lang-$code'),
      title: label,
      trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? c.iconActive : c.textTertiary),
      onTap: () => ref.read(databaseProvider).kvSet('ui.locale', code),
    );
  }
}
