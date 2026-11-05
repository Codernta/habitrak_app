import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../../data/models/health_news_article.dart';

class HealthNewsDetailPage extends StatefulWidget {
  final HealthNewsArticle article;
  final List<HealthNewsArticle> relatedArticles;

  const HealthNewsDetailPage({
    super.key,
    required this.article,
    this.relatedArticles = const [],
  });

  @override
  State<HealthNewsDetailPage> createState() => _HealthNewsDetailPageState();
}

class _HealthNewsDetailPageState extends State<HealthNewsDetailPage> {
  bool _isSaved = false;

  void _onToggleSave() {
    HapticFlow.light();
    setState(() => _isSaved = !_isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Study saved to reading list' : 'Study removed from reading list'),
        backgroundColor: const Color(0xff334d38),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onShareOrCopyLink() {
    HapticFlow.medium();
    Clipboard.setData(ClipboardData(text: '${widget.article.title}\n${widget.article.url}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Study link & citation copied to clipboard!'),
        backgroundColor: Color(0xff334d38),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textMuted = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff121412) : const Color(0xfffaf9f6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
          onPressed: () {
            HapticFlow.light();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isSaved ? primaryColor : textMuted,
            ),
            tooltip: 'Save study',
            onPressed: _onToggleSave,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: textMuted),
            tooltip: 'Share citation',
            onPressed: _onShareOrCopyLink,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges: Category, Read Time, Date
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(
                  label: widget.article.category,
                  icon: _getCategoryIcon(widget.article.category),
                  color: primaryColor,
                  isDark: isDark,
                ),
                _buildBadge(
                  label: '${widget.article.readTimeMinutes} min read',
                  icon: Icons.timer_outlined,
                  color: textMuted,
                  isDark: isDark,
                ),
                _buildBadge(
                  label: widget.article.pubDateString,
                  icon: Icons.calendar_today_outlined,
                  color: textMuted,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Headline
            Text(
              widget.article.title,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.3,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Source Attribution
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_rounded, size: 14, color: primaryColor),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.article.source,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PEER REVIEWED',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Key Takeaway / Abstract Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xff1e261e) : const Color(0xfff0f6f0)).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.biotech_rounded, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'STUDY SUMMARY & ABSTRACT',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.article.description,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Key Highlights Section
            if (widget.article.keyHighlights.isNotEmpty) ...[
              Text(
                'Key Clinical Findings',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.article.keyHighlights.map((highlight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 12, color: primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          highlight,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14.5,
                            height: 1.5,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Full Content / In-Depth Details
            Text(
              'Research Report',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.article.content,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 15,
                height: 1.65,
                color: textColor.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 28),

            // Actionable Habit Impact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    primaryColor.withValues(alpha: isDark ? 0.10 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.eco_rounded,
                          size: 16,
                          color: isDark ? const Color(0xff121412) : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'HABITRAK PRACTICAL TAKEAWAY',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.article.habitTakeaway,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Study Reference & Citation Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 18, color: textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'Study Reference',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.article.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    onTap: _onShareOrCopyLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Copy Study Citation',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Related Studies Carousel if provided
            if (widget.relatedArticles.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'More Health Studies',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.relatedArticles.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = widget.relatedArticles[index];
                    return _buildRelatedStudyMiniCard(item, isDark, primaryColor, textColor, textMuted);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedStudyMiniCard(
    HealthNewsArticle item,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color textMuted,
  ) {
    return PressableScale(
      onTap: () {
        HapticFlow.light();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HealthNewsDetailPage(
              article: item,
              relatedArticles: widget.relatedArticles.where((a) => a.id != item.id).toList(),
            ),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xff1a1e1a) : Colors.white).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryIcon(item.category), size: 12, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  item.category,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.readTimeMinutes} min read • Read study →',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('brain') || lower.contains('mind')) return Icons.psychology_outlined;
    if (lower.contains('nutrition') || lower.contains('diet')) return Icons.restaurant_outlined;
    if (lower.contains('aging') || lower.contains('longevity')) return Icons.hourglass_empty_rounded;
    if (lower.contains('fitness') || lower.contains('vitality')) return Icons.bolt_rounded;
    return Icons.biotech_outlined;
  }
}
