import 'package:flutter/material.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../../data/models/health_news_article.dart';
import '../pages/health_news_detail_page.dart';

class HealthNewsCard extends StatelessWidget {
  final HealthNewsArticle article;
  final List<HealthNewsArticle> allArticles;
  final double? width;
  final bool isHorizontalCard;

  const HealthNewsCard({
    super.key,
    required this.article,
    this.allArticles = const [],
    this.width,
    this.isHorizontalCard = false,
  });

  void _onTapCard(BuildContext context) {
    HapticFlow.selection();
    Navigator.of(context).push(
      AppPageRoute(
        page: HealthNewsDetailPage(
          article: article,
          relatedArticles: allArticles.where((a) => a.id != article.id).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textMuted = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return PressableScale(
      onTap: () => _onTapCard(context),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isDark ? const Color(0xff1f2620) : const Color(0xffffffff)).withValues(alpha: isDark ? 0.85 : 0.95),
              (isDark ? const Color(0xff181d18) : const Color(0xfff7faf7)).withValues(alpha: isDark ? 0.70 : 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.04 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Category tag and Read Time
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(article.category),
                          size: 13,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            article.category,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${article.readTimeMinutes} min',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.3,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),

            // Description / Snippet
            Text(
              article.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12.5,
                height: 1.4,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 10),

            // Habit Takeaway Mini-Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      article.habitTakeaway,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom row: Date & Read Study link
            Row(
              children: [
                Expanded(
                  child: Text(
                    article.pubDateString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11.5,
                      color: textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read Study',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('brain') || lower.contains('mind')) return Icons.psychology_rounded;
    if (lower.contains('nutrition') || lower.contains('diet')) return Icons.restaurant_rounded;
    if (lower.contains('aging') || lower.contains('longevity')) return Icons.hourglass_top_rounded;
    if (lower.contains('fitness') || lower.contains('vitality')) return Icons.bolt_rounded;
    return Icons.biotech_rounded;
  }
}
