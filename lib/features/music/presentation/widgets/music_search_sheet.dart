import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/features/music/models/soulful_track.dart';
import 'package:habitrak/features/music/services/soulful_music_service.dart';

/// Modal bottom sheet allowing users to explore and search royalty-free
/// yoga and meditation music (1 to 5 minutes duration) from free archives.
class MusicSearchSheet extends StatefulWidget {
  final Function(SoulfulTrack) onTrackSelected;

  const MusicSearchSheet({super.key, required this.onTrackSelected});

  static Future<void> show(
    BuildContext context, {
    required Function(SoulfulTrack) onTrackSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MusicSearchSheet(onTrackSelected: onTrackSelected),
    );
  }

  @override
  State<MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<MusicSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SoulfulMusicService _musicService = SoulfulMusicService();

  List<SoulfulTrack> _tracks = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';

  final List<String> _filterCategories = [
    'All',
    'Yoga',
    'Meditation',
    'Breathwork',
    'Ocean',
    'Rain',
  ];

  @override
  void initState() {
    super.initState();
    _tracks = SoulfulMusicService.curatedTracks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    final results = await _musicService.searchTracks(query);
    if (!mounted) return;
    setState(() {
      _tracks = results;
      _isLoading = false;
    });
  }

  void _onFilterTap(String filter) {
    HapticFeedback.lightImpact();
    setState(() => _selectedFilter = filter);
    if (filter == 'All') {
      _performSearch(_searchController.text);
    } else {
      _performSearch(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.94)
                : AppColors.lightSurface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              // Sheet Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.darkPrimaryContainer
                                    : AppColors.lightPrimaryContainer)
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.music_note,
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
                            'Soulful Music Library',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.lightOnSurface,
                            ),
                          ),
                          Text(
                            '1–5 min royalty-free audio for yoga & meditation',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkOnSurfaceVariant
                                  : AppColors.lightOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _performSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Search yoga, rain, singing bowl, zen...',
                    hintStyle: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkOutline
                          : AppColors.lightOutline,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filterCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _filterCategories[index];
                    final isSelected = _selectedFilter == cat;
                    return GestureDetector(
                      onTap: () => _onFilterTap(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkOnPrimary
                                      : Colors.white)
                                : (isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.lightOnSurface),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Tracks List View
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tracks.isEmpty
                    ? Center(
                        child: Text(
                          'No music tracks found.\nTry "yoga", "meditation", or "rain"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _tracks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          final isCurrent =
                              _musicService.currentTrack?.id == track.id;
                          final isPlaying =
                              isCurrent && _musicService.isPlaying;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? (isDark
                                            ? AppColors.darkPrimaryContainer
                                            : AppColors.lightPrimaryContainer)
                                        .withValues(alpha: 0.35)
                                  : (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? primaryColor.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    widget.onTrackSelected(track);
                                    _musicService.togglePlayPause(track);
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isPlaying
                                          ? primaryColor
                                          : (isDark
                                                    ? Colors.white
                                                    : Colors.black)
                                                .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isPlaying
                                          ? (isDark
                                                ? AppColors.darkOnPrimary
                                                : Colors.white)
                                          : primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkOnSurface
                                              : AppColors.lightOnSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${track.artist} • ${track.category}',
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.lightOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    track.formattedDuration,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom free license guarantee footer
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '100% Free & Royalty-Free (No licensing or paid fees)',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkOutline
                            : AppColors.lightOutline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
