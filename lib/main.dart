import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/controllers/auth_provider.dart';
import 'features/audio/controllers/audio_player_controller.dart';
import 'features/audio/controllers/audio_library_controller.dart';
import 'features/posts/controllers/post_list_controller.dart';
import 'core/api/api_service.dart';
import 'features/audio/services/audio_service.dart';
import 'features/posts/services/post_service.dart';
import 'features/admin/services/vibe_service.dart';
import 'features/admin/controllers/audio_controller.dart';
import 'features/admin/controllers/post_controller.dart';
import 'features/admin/controllers/vibe_controller.dart';
import 'core/widgets/audio_player_widget.dart';
import 'features/posts/pages/posts_page.dart';
import 'features/audio/pages/audio_library_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/admin/pages/admin_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  final apiService = ApiService();
  final audioService = AudioService(apiService);
  final postService = PostService(apiService);
  final vibeService = VibeService(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => AudioPlayerController()),
        ChangeNotifierProvider(create: (_) => AudioLibraryController(audioService)),
        ChangeNotifierProvider(create: (_) => PostListController(postService)),
        ChangeNotifierProvider(create: (_) => AudioController(audioService)),
        ChangeNotifierProvider(create: (_) => PostController(postService)),
        ChangeNotifierProvider(create: (_) => VibeController(vibeService)),
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
            if (auth.isAuthenticated)
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
      bottomNavigationBar: const AudioPlayerWidget(),
    );
  }
}
