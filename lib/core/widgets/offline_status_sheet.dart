import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/services/connectivity_service.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/core/widgets/offline_lottie_widget.dart';

/// Modal bottom sheet showcasing Habitrak's offline state with Lottie animation
/// and serene color aesthetics.
class OfflineStatusSheet extends StatefulWidget {
  const OfflineStatusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const OfflineStatusSheet(),
    );
  }

  @override
  State<OfflineStatusSheet> createState() => _OfflineStatusSheetState();
}

class _OfflineStatusSheetState extends State<OfflineStatusSheet> {
  bool _isChecking = false;

  Future<void> _handleRetry() async {
    HapticFeedback.mediumImpact();
    setState(() => _isChecking = true);

    final isNowOnline = await ConnectivityService().checkConnectivity();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (isNowOnline) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Internet connection restored!'),
          backgroundColor: Color(0xFF38573E),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still offline. Mindful offline mode remains active.'),
          backgroundColor: Color(0xff516870),
          duration: Duration(seconds: 2),
        ),
      );
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
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.92)
                : AppColors.lightSurface.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet drag handle
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

              // Theme-aligned Lottie animation
              const OfflineLottieWidget(width: 160, height: 160),
              const SizedBox(height: 12),

              // Title
              Text(
                'Mindful Offline Mode',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkOnSurface
                      : AppColors.lightOnSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'No internet connection detected. Take this quiet moment for yourself. Your daily habits, streaks, and reflections remain fully functional offline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkOnSurfaceVariant
                      : AppColors.lightOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // Feature Highlights Row
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.lightPrimaryContainer)
                          .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureItem(
                      Icons.self_improvement,
                      'Yoga & Zen',
                      primaryColor,
                    ),
                    _buildFeatureItem(
                      Icons.history_edu,
                      'Local Journal',
                      primaryColor,
                    ),
                    _buildFeatureItem(Icons.sync, 'Auto-Syncs', primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Retry & Dismiss Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.lightOutlineVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Keep Practicing',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.lightOnSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: isDark
                            ? AppColors.darkOnPrimary
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Check Internet',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
