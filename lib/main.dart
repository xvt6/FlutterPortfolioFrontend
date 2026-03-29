import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/posts_page.dart';
import 'screens/audio_library_page.dart';
import 'screens/login_page.dart';
import 'screens/admin_dashboard_page.dart';

void main() {
  final authProvider = AuthProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider..checkAuthStatus()),
      ],
      child: MyApp(authProvider: authProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainNavigationWrapper(title: 'Posts', child: PostsPage()),
        ),
        GoRoute(
          path: '/audio',
          builder: (context, state) => const MainNavigationWrapper(title: 'Audio Library', child: AudioLibraryPage()),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/admin',
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) {
              return '/login';
            }
            return null;
          },
          builder: (context, state) => const MainNavigationWrapper(title: 'Admin Dashboard', child: AdminDashboardPage()),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Audio Library App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class MainNavigationWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  const MainNavigationWrapper({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
                context.go('/');
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Posts'),
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.library_music),
              title: const Text('Audio Library'),
              onTap: () {
                Navigator.pop(context);
                context.go('/audio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin');
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
