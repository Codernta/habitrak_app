import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/animated_modal_sheet.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../bloc/habit_bloc.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();
  HabitCategory _selectedCategory = HabitCategory.mindfulness;

  String _searchQuery = '';
  HabitCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _showAddCustomHabitSheet() {
    showAnimatedModalSheet(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff1e201e)
                    : const Color(0xffffffff),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const HapticScrollPhysics(
                    detentDistance: 120.0,
                    triggerAtEdges: true,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Custom Habit',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xffe2e3df)
                              : const Color(0xff2f312f),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Habit Title',
                          labelStyle: TextStyle(
                            color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0x3dffffff)
                                  : const Color(0x3d000000),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a habit title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Category Selector
                      Text(
                        'Category',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xffc2c8c0)
                              : const Color(0xff615e56),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: HabitCategory.values.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat.displayName),
                                selected: isSelected,
                                selectedColor: (isDark ? AppColors.limeAccent : AppColors.obsidianBlack).withValues(alpha: 0.15),
                                onSelected: (selected) {
                                  if (selected) {
                                    HapticFlow.selection();
                                    setModalState(() {
                                      _selectedCategory = cat;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _targetController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Daily Goal Target',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0x3dffffff)
                                        : const Color(0x3d000000),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _unitController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Unit (e.g. L, mins)',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0x3dffffff)
                                        : const Color(0x3d000000),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            HapticFlow.play(HapticPresets.successSnap);
                            final target =
                                double.tryParse(_targetController.text) ?? 1.0;

                            context.read<HabitBloc>().add(
                              AddCustomHabitEvent(
                                title: _titleController.text.trim(),
                                category: _selectedCategory,
                                targetProgress: target,
                                unit: _unitController.text.trim(),
                              ),
                            );

                            _titleController.clear();
                            _targetController.clear();
                            _unitController.clear();

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Custom habit created!'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                          foregroundColor: isDark ? const Color(0xFF1E201E) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Create Habit'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addPresetHabit(
    String title,
    HabitCategory cat,
    double target,
    String unit,
    String? scheduledTime,
  ) {
    context.read<HabitBloc>().add(
      AddCustomHabitEvent(
        title: title,
        category: cat,
        targetProgress: target,
        unit: unit,
        scheduledTime: scheduledTime,
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"$title" added to your routine!')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final popularPresets = [
      {
        'title': 'Morning Sun',
        'desc': '15 mins • Circadian rhythm',
        'category': HabitCategory.health,
        'target': 15.0,
        'unit': 'mins',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'title': 'Gratitude Journal',
        'desc': '5 mins • Daily reflection',
        'category': HabitCategory.mindfulness,
        'target': 1.0,
        'unit': '',
        'icon': Icons.edit_document,
      },
      {
        'title': 'Plant Care',
        'desc': '10 mins • Grounding & focus',
        'category': HabitCategory.growth,
        'target': 10.0,
        'unit': 'mins',
        'icon': Icons.eco_rounded,
      },
      {
        'title': 'Deep Work Sprint',
        'desc': '45 mins • Uninterrupted flow',
        'category': HabitCategory.growth,
        'target': 45.0,
        'unit': 'mins',
        'icon': Icons.psychology_rounded,
      },
      {
        'title': 'Daily Walk',
        'desc': '30 mins • Cardio & fresh air',
        'category': HabitCategory.health,
        'target': 30.0,
        'unit': 'mins',
        'icon': Icons.directions_walk_rounded,
      },
      {
        'title': 'Evening Wind Down',
        'desc': '15 mins • Calm screen-free habits',
        'category': HabitCategory.mindfulness,
        'target': 15.0,
        'unit': 'mins',
        'icon': Icons.nightlight_round,
      },
      {
        'title': 'Cold Shower',
        'desc': '3 mins • Invigoration & focus',
        'category': HabitCategory.health,
        'target': 3.0,
        'unit': 'mins',
        'icon': Icons.shower_rounded,
      },
      {
        'title': 'Read 15 Pages',
        'desc': '20 mins • Continuous learning',
        'category': HabitCategory.growth,
        'target': 15.0,
        'unit': 'pages',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'Body Scan Meditation',
        'desc': '10 mins • Somatic awareness',
        'category': HabitCategory.mindfulness,
        'target': 10.0,
        'unit': 'mins',
        'icon': Icons.spa_rounded,
      },
    ];

    final filteredPresets = popularPresets.where((p) {
      final matchesCat =
          _filterCategory == null || p['category'] == _filterCategory;
      final title = (p['title'] as String).toLowerCase();
      final desc = (p['desc'] as String).toLowerCase();
      final matchesQuery =
          _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          desc.contains(_searchQuery);
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Habit Library',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.obsidianBlack,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const HapticScrollPhysics(
          detentDistance: 120.0,
          triggerAtEdges: true,
        ),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            StaggeredEntrance(
              index: 0,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search habits...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFFA0A5AD)
                        : const Color(0xFF7A7E85),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.limeAccentDark,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.charcoalCard
                      : Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.charcoalBorder
                          : const Color(0xFFE8E9EC),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: AppColors.limeAccentDark,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 1,
              child: PressableScale(
                onTap: () {
                  HapticFlow.light();
                  _showAddCustomHabitSheet();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E2124), const Color(0xFF16181A)]
                          : [const Color(0xFFF9FAFB), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.charcoalBorder
                          : const Color(0xFFE8E9EC),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeAccent.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.limeAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Custom',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.obsidianBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Design a routine that fits you',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFA0A5AD)
                                    : const Color(0xFF7A7E85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark
                            ? const Color(0xFFA0A5AD)
                            : const Color(0xFF7A7E85),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            StaggeredEntrance(
              index: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xffe2e3df)
                          : const Color(0xff2f312f),
                    ),
                  ),
                  if (_filterCategory != null)
                    TextButton(
                      onPressed: () {
                        HapticFlow.light();
                        setState(() => _filterCategory = null);
                      },
                      child: Text(
                        'Clear Filter',
                        style: TextStyle(
                          color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 3,
              child: SizedBox(
                height: 155,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children:
                      [
                        {
                          'title': 'Mindfulness',
                          'category': HabitCategory.mindfulness,
                          'subtitle': 'Curated habits for mental clarity',
                          'icon': Icons.self_improvement,
                          'color': AppColors.lavenderAccent,
                        },
                        {
                          'title': 'Health',
                          'category': HabitCategory.health,
                          'subtitle': 'Habits for active physical vitality',
                          'icon': Icons.favorite_rounded,
                          'color': AppColors.limeAccent,
                        },
                        {
                          'title': 'Growth',
                          'category': HabitCategory.growth,
                          'subtitle': 'Habits for lifelong learning',
                          'icon': Icons.auto_stories,
                          'color': const Color(0xffedb9c3),
                        },
                      ].asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;
                        final catType = cat['category'] as HabitCategory;
                        final isSelected = _filterCategory == catType;

                        return StaggeredEntrance(
                          index: idx,
                          slideAxis: Axis.horizontal,
                          child: GestureDetector(
                            onTap: () {
                              HapticFlow.selection();
                              setState(() {
                                _filterCategory = isSelected ? null : catType;
                              });
                            },
                            child: _buildCategoryCard(
                              cat['title'] as String,
                              cat['subtitle'] as String,
                              cat['icon'] as IconData,
                              cat['color'] as Color,
                              isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            StaggeredEntrance(
              index: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterCategory == null
                        ? 'Popular Habits'
                        : '${_filterCategory!.displayName} Habits',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xffe2e3df)
                          : const Color(0xff2f312f),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFlow.light();
                      setState(() {
                        _filterCategory = null;
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      _filterCategory != null || _searchQuery.isNotEmpty
                          ? 'RESET'
                          : 'VIEW ALL',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (filteredPresets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No habits found matching your filter.',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      color: isDark
                          ? const Color(0xffc2c8c0)
                          : const Color(0xff615e56),
                    ),
                  ),
                ),
              )
            else
              ...filteredPresets.asMap().entries.map((entry) {
                final preset = entry.value;
                final idx = entry.key;
                return StaggeredEntrance(
                  index: 5 + idx,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.charcoalCard
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? AppColors.charcoalBorder
                            : const Color(0xFFE8E9EC),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF24272B)
                                : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            preset['icon'] as IconData,
                            color: isDark
                                ? AppColors.limeAccent
                                : AppColors.obsidianBlack,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset['title'] as String,
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.obsidianBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset['desc'] as String,
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFFA0A5AD)
                                      : const Color(0xFF7A7E85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            HapticFlow.play(HapticPresets.successSnap);
                            _addPresetHabit(
                              preset['title'] as String,
                              preset['category'] as HabitCategory,
                              preset['target'] as double,
                              preset['unit'] as String,
                              preset['title'] == 'Gratitude Journal'
                                  ? '8:00 AM'
                                  : null,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16181A),
                            foregroundColor: AppColors.limeAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF2E3236),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'ADD',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 145,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e201e) : const Color(0xffffffff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.limeAccent : AppColors.obsidianBlack)
              : (isDark
                    ? const Color(0xff424842).withValues(alpha: 0.1)
                    : const Color(0xffdbdad7).withValues(alpha: 0.4)),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xffe2e3df)
                      : const Color(0xff2f312f),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                      : const Color(0xff615e56).withValues(alpha: 0.5),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
