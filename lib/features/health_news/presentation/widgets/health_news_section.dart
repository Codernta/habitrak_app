import 'package:flutter/material.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../../data/models/health_news_article.dart';
import '../../data/repositories/health_news_repository.dart';
import '../pages/health_news_feed_page.dart';
import 'health_news_card.dart';

class HealthNewsSection extends StatefulWidget {
  const HealthNewsSection({super.key});

  @override
  State<HealthNewsSection> createState() => _HealthNewsSectionState();
}

class _HealthNewsSectionState extends State<HealthNewsSection> {
  final HealthNewsRepository _repository = HealthNewsRepository();
  String _selectedCategoryId = 'all';
  List<HealthNewsArticle> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _repository.getHealthNews(
        categoryId: _selectedCategoryId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _articles = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load health studies.';
        });
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    if (categoryId == _selectedCategoryId) return;
    HapticFlow.selection();
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadArticles();
  }

  void _onOpenSeeAll() {
    HapticFlow.light();
    Navigator.of(context).push(
      AppPageRoute(
        page: HealthNewsFeedPage(initialCategoryId: _selectedCategoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textMuted = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.lightPrimaryContainer)
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.biotech_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HEALTH & SCIENCE NEWS',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Peer-reviewed studies & clinical breakthroughs',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // See All Button
            PressableScale(
              onTap: _onOpenSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Category Filter Chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: HealthNewsRepository.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = HealthNewsRepository.categories[index];
              final isSelected = cat.id == _selectedCategoryId;
              return PressableScale(
                onTap: () => _onCategorySelected(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.20)
                        : (isDark ? const Color(0xff1e221e) : Colors.white).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        cat.label,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primaryColor : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Carousel of Studies
        if (_isLoading)
          _buildLoadingSkeleton(isDark, primaryColor)
        else if (_errorMessage != null)
          _buildErrorCard(isDark, primaryColor, textMuted)
        else if (_articles.isEmpty)
          _buildEmptyCard(isDark, textMuted)
        else
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _articles.length + 1, // +1 for "Explore All" end-card
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                if (index == _articles.length) {
                  return _buildExploreAllCard(isDark, primaryColor, textColor, textMuted);
                }
                final article = _articles[index];
                return HealthNewsCard(
                  article: article,
                  allArticles: _articles,
                  width: 310,
                  isHorizontalCard: true,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(bool isDark, Color primaryColor) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xff1a1e1a) : Colors.white).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fetching latest health studies...',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                color: primaryColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark, Color primaryColor, Color textMuted) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xff1e1a1a) : const Color(0xfffff5f5)).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: textMuted, size: 28),
          const SizedBox(height: 8),
          Text(
            'Unable to fetch health studies',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          PressableScale(
            onTap: () => _loadArticles(forceRefresh: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(bool isDark, Color textMuted) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xff1a1e1a) : Colors.white).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'No studies currently available in this category.',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 13,
            color: textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildExploreAllCard(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color textMuted,
  ) {
    return PressableScale(
      onTap: _onOpenSeeAll,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xff182218) : const Color(0xffedf4ed)).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.explore_rounded, color: primaryColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              'Explore All\nStudies',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Search & Filter',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
