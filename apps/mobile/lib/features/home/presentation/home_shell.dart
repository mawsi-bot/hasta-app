import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/state_views.dart';
import '../../profile/presentation/profile_tab.dart';

/// Bottom navigation — exactly 5 items (DS navigation). Dating is never a tab.
/// Tab state is preserved (IndexedStack). Feed/Discover/Chat/Notifications are
/// Sprint 3–5 surfaces; in Sprint 1 they render their empty state, and the
/// offline banner is shown by the shell for every tab.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool online = ref.isOnline;
    final List<Widget> tabs = <Widget>[
      EmptyState(key: const Key('tab-home'), icon: Icons.groups_outlined, title: l.feedEmpty, body: l.comingSoon),
      EmptyState(key: const Key('tab-discover'), icon: Icons.explore_outlined, title: l.searchEmpty, body: l.comingSoon),
      EmptyState(
          key: const Key('tab-chat'),
          icon: Icons.chat_bubble_outline,
          title: l.chatEmpty,
          body: l.comingSoon,
          actionLabel: l.chatEmptyCta),
      EmptyState(
          key: const Key('tab-notifications'), icon: Icons.notifications_none, title: l.notificationsEmpty, body: l.comingSoon),
      const ProfileTab(key: Key('tab-profile')),
    ];
    // Text scale above 1.3 hides nav labels (DS navigation.labelHideAboveTextScale).
    final bool hideLabels = MediaQuery.textScalerOf(context).scale(10) / 10 > 1.3;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            if (!online) OfflineBanner(message: l.offlineBanner),
            Expanded(child: IndexedStack(index: _index, children: tabs)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        labelBehavior:
            hideLabels ? NavigationDestinationLabelBehavior.alwaysHide : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(
              icon: const Icon(Icons.explore_outlined), selectedIcon: const Icon(Icons.explore), label: l.navDiscover),
          NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: l.navChat),
          NavigationDestination(
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications),
              label: l.navNotifications),
          NavigationDestination(
              icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l.navProfile),
        ],
      ),
    );
  }
}
