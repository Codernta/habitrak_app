import 'package:flutter/material.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../../data/models/health_news_article.dart';
import '../../data/repositories/health_news_repository.dart';
import '../widgets/health_news_card.dart';

class HealthNewsFeedPage extends StatefulWidget {
  final String initialCategoryId;

  const HealthNewsFeedPage({
    super.key,
    this.initialCategoryId = 'all',
  });

  @override
  State<HealthNewsFeedPage> createState() => _HealthNewsFeedPageState();
}

class _HealthNewsFeedPageState extends State<HealthNewsFeedPage> {
  final HealthNewsRepository _repository = HealthNewsRepository();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedCategoryId;
  List<HealthNewsArticle> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool forceRefresh = false}) async {
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
          _errorMessage = 'Unable to load health studies right now.';
        });
      }
    }
  }

  List<HealthNewsArticle> get _filteredArticles {
    if (_searchQuery.trim().isEmpty) {
      return _articles;
    }
    final q = _searchQuery.toLowerCase().trim();
    return _articles.where((article) {
      return article.title.toLowerCase().contains(q) ||
          article.description.toLowerCase().contains(q) ||
          article.category.toLowerCase().contains(q) ||
          article.habitTakeaway.toLowerCase().contains(q);
    }).toList();
  }

  void _onCategorySelected(String categoryId) {
    if (categoryId == _selectedCategoryId) return;
    HapticFlow.selection();
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadNews();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final textMuted = isDark ? AppColors.darkOnSurfaceVariant : AppColors.lightOnSurfaceVariant;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final displayArticles = _filteredArticles;

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
        title: Text(
          'Health & Science News',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor),
            tooltip: 'Refresh studies',
            onPressed: () {
              HapticFlow.light();
              _loadNews(forceRefresh: true);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNews(forceRefresh: true),
        color: primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Search Bar & Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          color: textColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search health studies, diet, brain, sleep...',
                          hintStyle: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: textMuted,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, color: primaryColor, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Filter Pills
                    SizedBox(
                      height: 38,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? const Color(0xff1e221e) : Colors.white)
                                        .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white12 : Colors.black12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat.icon, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? const Color(0xff121412) : Colors.white)
                                          : textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Articles List / State Handling
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: textMuted),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          color: textMuted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadNews(forceRefresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? const Color(0xff121412) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (displayArticles.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No health studies found matching "$_searchQuery".',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          color: textMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final article = displayArticles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HealthNewsCard(
                          article: article,
                          allArticles: _articles,
                          isHorizontalCard: false,
                        ),
                      );
                    },
                    childCount: displayArticles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
