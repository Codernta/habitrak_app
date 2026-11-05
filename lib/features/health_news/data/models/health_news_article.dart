/// Model representing a health, medical, or scientific study news article.
class HealthNewsArticle {
  final String id;
  final String title;
  final String description;
  final String content;
  final DateTime? publishedAt;
  final String pubDateString;
  final String url;
  final String category;
  final String source;
  final String? imageUrl;
  final List<String> keyHighlights;
  final String habitTakeaway;
  final int readTimeMinutes;

  const HealthNewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    this.publishedAt,
    required this.pubDateString,
    required this.url,
    required this.category,
    this.source = 'ScienceDaily / Health Research',
    this.imageUrl,
    this.keyHighlights = const [],
    required this.habitTakeaway,
    this.readTimeMinutes = 3,
  });

  /// Factory constructor to parse from rss2json item map.
  factory HealthNewsArticle.fromRss2Json(Map<String, dynamic> json, {String defaultCategory = 'Health & Medicine'}) {
    final rawTitle = json['title'] as String? ?? 'New Health Study Finding';
    final cleanTitle = _cleanHtmlText(rawTitle);

    final rawDesc = json['description'] as String? ?? '';
    final cleanDesc = _cleanHtmlText(rawDesc);

    final rawContent = json['content'] as String? ?? rawDesc;
    final cleanContent = _cleanHtmlText(rawContent);

    final link = json['link'] as String? ?? json['guid'] as String? ?? '';
    final pubDateRaw = json['pubDate'] as String? ?? '';
    DateTime? parsedDate;
    if (pubDateRaw.isNotEmpty) {
      try {
        parsedDate = DateTime.tryParse(pubDateRaw);
      } catch (_) {}
    }

    final formattedDate = _formatDisplayDate(parsedDate, pubDateRaw);
    final category = _detectCategory(cleanTitle, cleanDesc, defaultCategory);
    final habitTakeaway = _generateHabitTakeaway(cleanTitle, cleanDesc, category);
    final highlights = _extractKeyHighlights(cleanDesc.isNotEmpty ? cleanDesc : cleanContent);
    final readTime = _calculateReadTime(cleanContent.isNotEmpty ? cleanContent : cleanDesc);

    // Extract thumbnail/image if available
    String? imgUrl = json['thumbnail'] as String?;
    if (imgUrl == null || imgUrl.isEmpty) {
      final enclosure = json['enclosure'];
      if (enclosure is Map && enclosure['link'] != null && enclosure['link'].toString().isNotEmpty) {
        imgUrl = enclosure['link'].toString();
      }
    }

    return HealthNewsArticle(
      id: link.isNotEmpty ? link : cleanTitle.hashCode.toString(),
      title: cleanTitle,
      description: cleanDesc,
      content: cleanContent.isNotEmpty ? cleanContent : cleanDesc,
      publishedAt: parsedDate,
      pubDateString: formattedDate,
      url: link,
      category: category,
      source: 'ScienceDaily / Clinical Studies',
      imageUrl: imgUrl,
      keyHighlights: highlights,
      habitTakeaway: habitTakeaway,
      readTimeMinutes: readTime,
    );
  }

  /// Create article from raw XML item (for direct RSS fallback).
  factory HealthNewsArticle.fromXml({
    required String title,
    required String link,
    required String description,
    required String pubDate,
    String defaultCategory = 'Health & Medicine',
  }) {
    final cleanTitle = _cleanHtmlText(title);
    final cleanDesc = _cleanHtmlText(description);
    final category = _detectCategory(cleanTitle, cleanDesc, defaultCategory);
    final habitTakeaway = _generateHabitTakeaway(cleanTitle, cleanDesc, category);
    final highlights = _extractKeyHighlights(cleanDesc);
    final readTime = _calculateReadTime(cleanDesc);

    return HealthNewsArticle(
      id: link.isNotEmpty ? link : cleanTitle.hashCode.toString(),
      title: cleanTitle,
      description: cleanDesc,
      content: cleanDesc,
      pubDateString: pubDate.isNotEmpty ? pubDate : 'Recently Published',
      url: link,
      category: category,
      source: 'ScienceDaily / Clinical Studies',
      keyHighlights: highlights,
      habitTakeaway: habitTakeaway,
      readTimeMinutes: readTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'publishedAt': publishedAt?.toIso8601String(),
      'pubDateString': pubDateString,
      'url': url,
      'category': category,
      'source': source,
      'imageUrl': imageUrl,
      'keyHighlights': keyHighlights,
      'habitTakeaway': habitTakeaway,
      'readTimeMinutes': readTimeMinutes,
    };
  }

  factory HealthNewsArticle.fromJson(Map<String, dynamic> json) {
    return HealthNewsArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'] as String) : null,
      pubDateString: json['pubDateString'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: json['category'] as String? ?? 'Health & Medicine',
      source: json['source'] as String? ?? 'ScienceDaily',
      imageUrl: json['imageUrl'] as String?,
      keyHighlights: (json['keyHighlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      habitTakeaway: json['habitTakeaway'] as String? ?? 'Maintain a balanced, consistent daily wellness routine.',
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 3,
    );
  }

  // --- Helper parsing methods ---

  static String _cleanHtmlText(String raw) {
    if (raw.isEmpty) return '';
    var text = raw;

    // Strip common HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // Decode HTML entities
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&lsquo;', '‘')
        .replaceAll('&rsquo;', '’')
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return text;
  }

  static String _formatDisplayDate(DateTime? date, String raw) {
    if (date != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    if (raw.isNotEmpty) {
      final parts = raw.split(' ');
      if (parts.length >= 3) {
        return parts.take(3).join(' ');
      }
      return raw;
    }
    return 'Recent Study';
  }

  static String _detectCategory(String title, String desc, String defaultCategory) {
    final combined = '$title $desc'.toLowerCase();
    if (combined.contains('brain') || combined.contains('memory') || combined.contains('alzheimer') || combined.contains('anxiety') || combined.contains('stress') || combined.contains('neuro')) {
      return 'Mind & Brain';
    }
    if (combined.contains('diet') || combined.contains('nutrition') || combined.contains('food') || combined.contains('sugar') || combined.contains('protein') || combined.contains('potassium') || combined.contains('eating')) {
      return 'Nutrition & Diet';
    }
    if (combined.contains('aging') || combined.contains('longevity') || combined.contains('lifespan') || combined.contains('repair') || combined.contains('elderly')) {
      return 'Longevity & Aging';
    }
    if (combined.contains('exercise') || combined.contains('muscle') || combined.contains('walking') || combined.contains('fitness') || combined.contains('cardio') || combined.contains('movement')) {
      return 'Fitness & Vitality';
    }
    if (combined.contains('sleep') || combined.contains('circadian') || combined.contains('rest')) {
      return 'Sleep & Recovery';
    }
    return defaultCategory;
  }

  static String _generateHabitTakeaway(String title, String desc, String category) {
    final lower = '$title $desc'.toLowerCase();

    if (lower.contains('potassium') || lower.contains('blood pressure') || lower.contains('salt')) {
      return 'Incorporate potassium-rich whole foods like bananas, spinach, and avocados to naturally support arterial balance alongside hydration habits.';
    }
    if (lower.contains('ultra-processed') || lower.contains('junk food') || lower.contains('diet')) {
      return 'Replace one processed snack daily with whole fruits, nuts, or seeds to preserve metabolic rhythm and dopamine sensitivity.';
    }
    if (lower.contains('muscle') || lower.contains('strength') || lower.contains('exercise')) {
      return 'Schedule at least 15-20 minutes of resistance training or brisk movement today to stimulate muscular cellular renewal.';
    }
    if (lower.contains('brain') || lower.contains('memory') || lower.contains('alzheimer')) {
      return 'Support cognitive resilience through 10 minutes of daily mindfulness meditation and regular aerobic activity.';
    }
    if (lower.contains('sleep') || lower.contains('circadian') || lower.contains('daylight')) {
      return 'Prioritize morning sunlight exposure within 30 minutes of waking to anchor your body clock and improve sleep quality.';
    }
    if (lower.contains('tea') || lower.contains('antioxidant')) {
      return 'Make mindful tea drinking an afternoon ritual for a gentle polyphenol boost that supports vascular resilience.';
    }
    if (lower.contains('peanuts') || lower.contains('nuts')) {
      return 'Adding a small handful of unsalted nuts to your morning routine can support sustained energy and neuro-protective insulin health.';
    }
    if (lower.contains('anxiety') || lower.contains('fear') || lower.contains('ptsd')) {
      return 'Practice grounding box-breathing when stressors arise to signal physical safety to your nervous system.';
    }

    switch (category) {
      case 'Mind & Brain':
        return 'Engage in a focused 5-minute breathwork session to down-regulate nervous tension and sharpen mental clarity.';
      case 'Nutrition & Diet':
        return 'Hydrate with a glass of water before every meal and focus on whole, unrefined foods to stabilize daily energy levels.';
      case 'Longevity & Aging':
        return 'Consistency in daily movement and restorative sleep is the scientifically verified cornerstone of longevity.';
      case 'Fitness & Vitality':
        return 'Aim for continuous gentle movement throughout your day rather than prolonged sedentary stretches.';
      default:
        return 'Apply this science by aligning your daily habit trackers with regular sleep, wholesome nutrition, and intentional movement.';
    }
  }

  static List<String> _extractKeyHighlights(String text) {
    if (text.isEmpty) return const [];
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    if (sentences.isEmpty) {
      return [text];
    }
    return sentences.take(3).toList();
  }

  static int _calculateReadTime(String text) {
    final words = text.split(RegExp(r'\s+')).length;
    final minutes = (words / 180).ceil();
    return minutes < 2 ? 2 : (minutes > 8 ? 8 : minutes);
  }
}
