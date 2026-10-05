import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../chat/people_screen.dart';
import '../feed/feed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../tutor/tutor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const pages = [FeedScreen(), PeopleScreen(), TutorScreen(), NotificationsScreen(), ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: l.home),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: l.chat),
          NavigationDestination(icon: const Icon(Icons.school_outlined), label: l.tutor),
          NavigationDestination(icon: const Icon(Icons.notifications_none), label: l.notifications),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l.profile),
        ],
      ),
    );
  }
}
