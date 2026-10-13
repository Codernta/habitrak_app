import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/core/widgets/offline_lottie_widget.dart';
import 'package:habitrak/core/widgets/offline_global_indicator.dart';
import 'package:habitrak/features/music/presentation/widgets/soulful_music_card.dart';
import 'package:habitrak/features/music/presentation/widgets/waveform_visualizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('Offline Widgets Tests', () {
    testWidgets('OfflineLottieWidget renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const OfflineLottieWidget(width: 150, height: 150),
        ),
      );

      expect(find.byType(OfflineLottieWidget), findsOneWidget);
    });

    testWidgets('OfflineGlobalIndicator renders wrapped child', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const OfflineGlobalIndicator(
            child: Text('Main Content Under Indicator'),
          ),
        ),
      );

      expect(find.text('Main Content Under Indicator'), findsOneWidget);
    });
  });

  group('SoulfulMusicCard Tests', () {
    testWidgets('WaveformVisualizer renders in playing and paused modes',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WaveformVisualizer(isPlaying: false),
        ),
      );
      expect(find.byType(WaveformVisualizer), findsOneWidget);

      await tester.pumpWidget(
        buildTestableWidget(
          const WaveformVisualizer(isPlaying: true),
        ),
      );
      expect(find.byType(WaveformVisualizer), findsOneWidget);
    });

    testWidgets('SoulfulMusicCard renders title and audio controls',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SingleChildScrollView(child: SoulfulMusicCard()),
        ),
      );

      expect(find.text("TODAY'S SOULFUL MUSIC"), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });
  });
}
