import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/drift/app_database.dart';
import '../../../core/design/hasta_theme.dart';
import '../../../core/design/tokens.dart';
import '../../../core/providers.dart';
import '../../../core/text/zawgyi.dart';
import '../../../shared/widgets/hasta_button.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/profile.dart';

/// Edit profile basics. Saving is local-first: works offline, syncs via outbox.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.initial});
  final LocalProfile initial;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.initial.displayName ?? '');
  late final TextEditingController _username = TextEditingController(text: widget.initial.username ?? '');
  late final TextEditingController _bio = TextEditingController(text: widget.initial.bio ?? '');
  late String? _birthDate = widget.initial.birthDate;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? _nz(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool online = ref.read(onlineProvider).valueOrNull ?? true;
    setState(() => _saving = true);
    final String id = ref.read(authControllerProvider).account!.id;
    await ref.read(profileRepositoryProvider).saveLocal(
          id,
          ProfileDraft(
            displayName: _nz(_name.text),
            username: _nz(_username.text),
            bio: _bio.text.trim(),
            birthDate: _birthDate,
          ),
        );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(online ? l.profileSaved : l.profileSyncPending)));
    Navigator.of(context).pop();
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      initialDate: _birthDate != null ? DateTime.parse(_birthDate!) : DateTime(now.year - 20),
    );
    if (d != null) {
      setState(() => _birthDate =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final HastaColors c = context.colors;
    final bool online = ref.isOnline;
    return Scaffold(
      appBar: AppBar(title: Text(l.profileEdit)),
      body: Column(
        children: <Widget>[
          if (!online) OfflineBanner(message: l.offlineBanner),
          Expanded(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(HastaSpace.screenHorizontalPadding),
                children: <Widget>[
                  TextFormField(
                    key: const Key('field-display-name'),
                    controller: _name,
                    maxLength: ProfileDraft.displayNameMax,
                    decoration: InputDecoration(labelText: l.profileDisplayName),
                    style: HastaType.body.copyWith(color: c.textPrimary),
                    validator: (String? v) => looksLikeZawgyi(v ?? '') ? l.zawgyiDetected : null,
                  ),
                  const SizedBox(height: HastaSpace.s12),
                  TextFormField(
                    key: const Key('field-username'),
                    controller: _username,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.profileUsername, prefixText: '@', helperText: l.profileUsernameRule),
                    style: HastaType.body.copyWith(color: c.textPrimary),
                    validator: (String? v) {
                      final String s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      return ProfileDraft.usernamePattern.hasMatch(s) ? null : l.profileUsernameRule;
                    },
                  ),
                  const SizedBox(height: HastaSpace.s12),
                  TextFormField(
                    key: const Key('field-bio'),
                    controller: _bio,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: ProfileDraft.bioMax,
                    decoration: InputDecoration(labelText: l.profileBio),
                    style: HastaType.body.copyWith(color: c.textPrimary),
                    validator: (String? v) => looksLikeZawgyi(v ?? '')
                        ? l.zawgyiDetected
                        : ((v ?? '').length > ProfileDraft.bioMax ? l.profileBioTooLong : null),
                  ),
                  const SizedBox(height: HastaSpace.s12),
                  InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: l.profileBirthDate, suffixIcon: const Icon(Icons.calendar_today_outlined)),
                      child: Text(_birthDate ?? '—', style: HastaType.body.copyWith(color: c.textPrimary)),
                    ),
                  ),
                  const SizedBox(height: HastaSpace.s24),
                  HastaButton(key: const Key('save-profile'), label: l.save, loading: _saving, onPressed: _save),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
