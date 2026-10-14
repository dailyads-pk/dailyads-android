import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/saved_store.dart';
import 'screens/browse_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/search_screen.dart';
import 'screens/today_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SavedStore.instance.load();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Sheet.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const DailyAdsApp());
}

class DailyAdsApp extends StatelessWidget {
  const DailyAdsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DailyAds.pk',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeShell(),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [TodayScreen(), BrowseScreen(), SearchScreen(), SavedScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.newspaper_outlined), selectedIcon: Icon(Icons.newspaper), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}
