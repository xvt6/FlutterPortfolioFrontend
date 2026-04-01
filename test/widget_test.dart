// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:android_studio/main.dart';
import 'package:android_studio/features/auth/controllers/auth_provider.dart';
import 'package:android_studio/features/audio/controllers/audio_player_controller.dart';

import 'package:android_studio/features/posts/controllers/post_list_controller.dart';
import 'package:android_studio/features/posts/services/post_service.dart';
import 'package:android_studio/features/audio/controllers/audio_library_controller.dart';
import 'package:android_studio/features/audio/services/audio_service.dart';
import 'package:android_studio/core/api/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    final audioProvider = AudioPlayerController();
    final apiService = ApiService();
    final postService = PostService(apiService);
    final audioService = AudioService(apiService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AudioPlayerController>.value(value: audioProvider),
          ChangeNotifierProvider<PostListController>(create: (_) => PostListController(postService)),
          ChangeNotifierProvider<AudioLibraryController>(create: (_) => AudioLibraryController(audioService)),
        ],
        child: MyApp(authProvider: authProvider),
      ),
    );

    // Wait for the initialization timer in AudioPlayerController
    await tester.pump(Duration.zero);

    // Verify that our app starts on the Posts page.
    expect(find.text('Posts'), findsAtLeast(1));
  });
}
