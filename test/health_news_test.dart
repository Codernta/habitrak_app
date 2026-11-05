import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/features/health_news/data/models/health_news_article.dart';
import 'package:habitrak/features/health_news/data/repositories/health_news_repository.dart';
import 'package:habitrak/features/health_news/presentation/pages/health_news_detail_page.dart';
import 'package:habitrak/features/health_news/presentation/pages/health_news_feed_page.dart';
import 'package:habitrak/features/health_news/presentation/widgets/health_news_card.dart';
import 'package:habitrak/features/health_news/presentation/widgets/health_news_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthNewsArticle Entity Tests', () {
    test('Correctly parses from rss2json with HTML entities and tags removed', () {
      final json = {
        'title': 'Study: &quot;Super Protein&quot; repairs &amp; revitalizes muscles',
        'description': '<p>Scientists found that <b>Super HGF</b> protects cells from damage.</p>',
        'content': '<p>Full study report on cellular regeneration.</p>',
        'link': 'https://example.com/study1',
        'pubDate': '2026-11-04 12:00:00',
        'thumbnail': 'https://example.com/thumb.jpg',
      };

      final article = HealthNewsArticle.fromRss2Json(json);

      expect(article.title, 'Study: "Super Protein" repairs & revitalizes muscles');
      expect(article.description, 'Scientists found that Super HGF protects cells from damage.');
      expect(article.url, 'https://example.com/study1');
      expect(article.imageUrl, 'https://example.com/thumb.jpg');
      expect(article.category, anyOf([contains('Fitness'), contains('Aging'), contains('Longevity'), contains('Nutrition')]));
      expect(article.readTimeMinutes, greaterThanOrEqualTo(2));
      expect(article.habitTakeaway, isNotEmpty);
    });

    test('Correctly detects categories and generates tailored habit takeaways', () {
      final brainArticle = HealthNewsArticle.fromRss2Json({
        'title': 'New discovery links hippocampus blood flow to memory retention',
        'description': 'Researchers analyzed brain activity in older adults.',
        'link': 'https://example.com/brain',
      });
      expect(brainArticle.category, 'Mind & Brain');
      expect(brainArticle.habitTakeaway, anyOf([contains('mindfulness'), contains('meditation'), contains('breathwork'), contains('resilience')]));

      final nutritionArticle = HealthNewsArticle.fromRss2Json({
        'title': 'Potassium in diet reduces blood pressure and arterial stiffness',
        'description': 'Combining reduced sodium with higher potassium intake optimizes kidney function.',
        'link': 'https://example.com/nutrition',
      });
      expect(nutritionArticle.category, 'Nutrition & Diet');
      expect(nutritionArticle.habitTakeaway, anyOf([contains('potassium'), contains('foods')]));
    });

    test('Serializes to and from JSON cleanly', () {
      const article = HealthNewsArticle(
        id: '123',
        title: 'Daily Walking Study',
        description: 'Walking 7,000 steps lowers mortality.',
        content: 'Full details of step counts and cardiovascular health.',
        pubDateString: 'Nov 4, 2026',
        url: 'https://example.com/walking',
        category: 'Fitness & Vitality',
        habitTakeaway: 'Take a brisk 20-minute walk after meals.',
        readTimeMinutes: 3,
      );

      final map = article.toJson();
      final reconstructed = HealthNewsArticle.fromJson(map);

      expect(reconstructed.id, '123');
      expect(reconstructed.title, 'Daily Walking Study');
      expect(reconstructed.category, 'Fitness & Vitality');
      expect(reconstructed.habitTakeaway, 'Take a brisk 20-minute walk after meals.');
    });
  });

  group('HealthNewsRepository Tests', () {
    final repository = HealthNewsRepository();

    test('Repository contains standard health categories', () {
      expect(HealthNewsRepository.categories, isNotEmpty);
      final ids = HealthNewsRepository.categories.map((c) => c.id).toList();
      expect(ids, containsAll(['all', 'brain', 'nutrition', 'longevity', 'fitness']));
    });

    test('getHealthNews returns curated health studies on offline or timeout fallback', () async {
      final articles = await repository.getHealthNews(categoryId: 'all');
      expect(articles, isNotEmpty);
      expect(articles.length, greaterThanOrEqualTo(5));

      for (final article in articles) {
        expect(article.title, isNotEmpty);
        expect(article.description, isNotEmpty);
        expect(article.url, isNotEmpty);
        expect(article.habitTakeaway, isNotEmpty);
      }
    });

    test('searchHealthNews accurately filters by keywords', () async {
      final results = await repository.searchHealthNews('muscle');
      expect(results, isNotEmpty);
      for (final item in results) {
        final combined = '${item.title} ${item.description} ${item.habitTakeaway}'.toLowerCase();
        expect(combined, contains('muscle'));
      }
    });
  });

  group('HealthNews Widgets Tests', () {
    const testArticle = HealthNewsArticle(
      id: 'test-article-1',
      title: 'Stanford Scientists Discover AI Molecule for Metabolic Balance',
      description: 'A newly identified peptide promotes satiety and metabolic rhythm.',
      content: 'Detailed laboratory findings on appetite signaling pathways.',
      pubDateString: 'Nov 4, 2026',
      url: 'https://example.com/stanford-study',
      category: 'Nutrition & Diet',
      keyHighlights: [
        'Peptide balances gut satiety hormones.',
        'Early trials demonstrate lean mass preservation.',
      ],
      habitTakeaway: 'Eat protein and fiber first at every meal.',
      readTimeMinutes: 3,
    );

    testWidgets('HealthNewsCard renders title, category, and habit takeaway', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HealthNewsCard(
              article: testArticle,
              width: 300,
              isHorizontalCard: true,
            ),
          ),
        ),
      );

      expect(find.text(testArticle.title), findsOneWidget);
      expect(find.text(testArticle.category), findsOneWidget);
      expect(find.textContaining('min'), findsOneWidget);
      expect(find.text(testArticle.habitTakeaway), findsOneWidget);
      expect(find.text('Read Study'), findsOneWidget);
    });

    testWidgets('HealthNewsDetailPage renders study findings, takeaways, and citation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthNewsDetailPage(article: testArticle),
        ),
      );

      expect(find.text(testArticle.title), findsOneWidget);
      expect(find.text('STUDY SUMMARY & ABSTRACT'), findsOneWidget);
      expect(find.text(testArticle.description), findsOneWidget);
      expect(find.text('HABITRAK PRACTICAL TAKEAWAY'), findsOneWidget);
      expect(find.text(testArticle.habitTakeaway), findsOneWidget);
      expect(find.text('Research Report'), findsOneWidget);
      expect(find.text('Study Reference'), findsOneWidget);
      expect(find.text('Copy Study Citation'), findsOneWidget);
    });

    testWidgets('HealthNewsSection renders header, category chips, and See All button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HealthNewsSection(),
            ),
          ),
        ),
      );

      expect(find.text('HEALTH & SCIENCE NEWS'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('All Studies'), findsOneWidget);
      expect(find.text('Mind & Brain'), findsOneWidget);
      expect(find.text('Nutrition & Diet'), findsOneWidget);
    });

    testWidgets('HealthNewsFeedPage renders search bar and category filters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthNewsFeedPage(),
        ),
      );

      expect(find.text('Health & Science News'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Studies'), findsOneWidget);
    });
  });
}
