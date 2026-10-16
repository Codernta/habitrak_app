import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/services/connectivity_service.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/core/widgets/offline_status_sheet.dart';

/// A non-intrusive global banner that smoothly slides in when the device
/// drops offline, allowing the user to view the offline state modal or dismiss.
class OfflineGlobalIndicator extends StatefulWidget {
  final Widget child;

  const OfflineGlobalIndicator({super.key, required this.child});

  @override
  State<OfflineGlobalIndicator> createState() => _OfflineGlobalIndicatorState();
}

class _OfflineGlobalIndicatorState extends State<OfflineGlobalIndicator> {
  late final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;
  bool _showReconnectedBanner = false;
  Timer? _reconnectedDismissTimer;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();
    _isOnline = _connectivityService.isOnline;

    _subscription = _connectivityService.isOnlineStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          if (!isOnline) {
            _showReconnectedBanner = false;
            _reconnectedDismissTimer?.cancel();
          } else if (!_isOnline && isOnline) {
            // Just came back online
            _showReconnectedBanner = true;
            _reconnectedDismissTimer?.cancel();
            _reconnectedDismissTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _showReconnectedBanner = false);
              }
            });
          }
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _reconnectedDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showBanner = !_isOnline || _showReconnectedBanner;

    return Stack(
      children: [
        widget.child,
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              offset: showBanner ? Offset.zero : const Offset(0, -1.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: showBanner ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: !_isOnline
                              ? (isDark
                                    ? const Color(
                                        0xff2a2323,
                                      ).withValues(alpha: 0.88)
                                    : const Color(
                                        0xfffdf2f2,
                                      ).withValues(alpha: 0.92))
                              : (isDark
                                    ? const Color(
                                        0xff1e2e20,
                                      ).withValues(alpha: 0.88)
                                    : const Color(
                                        0xffeef7ef,
                                      ).withValues(alpha: 0.92)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isOnline
                                ? (isDark
                                      ? AppColors.darkTertiary.withValues(
                                          alpha: 0.3,
                                        )
                                      : const Color(
                                          0xffe8a2af,
                                        ).withValues(alpha: 0.5))
                                : (isDark
                                      ? AppColors.darkPrimary.withValues(
                                          alpha: 0.4,
                                        )
                                      : AppColors.lightPrimary.withValues(
                                          alpha: 0.5,
                                        )),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              !_isOnline
                                  ? Icons.wifi_off_rounded
                                  : Icons.wifi_rounded,
                              size: 18,
                              color: !_isOnline
                                  ? (isDark
                                        ? AppColors.darkTertiary
                                        : const Color(0xffc25e6b))
                                  : (isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                !_isOnline
                                    ? 'Offline Mode • Practicing Mindfully'
                                    : 'Back Online • Synced with Habitrak',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.lightOnSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!_isOnline) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  OfflineStatusSheet.show(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Details',
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
