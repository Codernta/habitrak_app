import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import '../bloc/wearable_sync_bloc.dart';
import '../bloc/wearable_sync_event.dart';
import '../bloc/wearable_sync_state.dart';

class WearablesHubModal extends StatelessWidget {
  const WearablesHubModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WearablesHubModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF16181A) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.obsidianBlack;
    final textMuted = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85);
    final borderCol = isDark ? const Color(0xFF2A2D32) : const Color(0xFFE5E7EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF33373E) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.watch_rounded,
                          color: Color(0xFF1E201E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wearables & Health AI',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              Platform.isIOS ? 'Apple HealthKit Integration' : 'Android Health Connect',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: textMuted),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          Expanded(
            child: BlocBuilder<WearableSyncBloc, WearableSyncState>(
              builder: (context, state) {
                if (state is WearableSyncLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WearableSyncSuccess) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // 1. Connection & Sync Card
                      _buildSyncStatusCard(context, state, isDark, textPrimary, textMuted),
                      const SizedBox(height: 16),

                      // 2. AI Daily Morning Briefing Card
                      if (state.latestInsight != null) ...[
                        _buildAIBriefingCard(context, state.latestInsight!, isDark, textPrimary, textMuted),
                        const SizedBox(height: 16),
                      ],

                      // 3. Automated Habit Links
                      _buildAutomatedHabitsCard(context, state, isDark, textPrimary, textMuted),
                      const SizedBox(height: 16),

                      // 4. Connected Devices
                      _buildConnectedDevicesCard(context, state, isDark, textPrimary, textMuted),
                      const SizedBox(height: 32),
                    ],
                  );
                }

                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<WearableSyncBloc>().add(InitializeWearablesEvent());
                    },
                    child: const Text('Initialize Wearables'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(
    BuildContext context,
    WearableSyncSuccess state,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final hasPerms = state.hasPermissions;
    final isSyncing = state.isSyncing;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3238) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasPerms ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: hasPerms ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasPerms ? 'Connected & Authorized' : 'Permission Required',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.lastSyncedAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Synced ${_formatRelativeTime(state.lastSyncedAt!)}',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Action Button
          if (!hasPerms)
            ElevatedButton.icon(
              onPressed: () {
                HapticFlow.medium();
                context.read<WearableSyncBloc>().add(RequestHealthPermissionsEvent());
              },
              icon: const Icon(Icons.security_rounded, size: 18),
              label: const Text('Authorize Apple Health / Health Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeAccent,
                foregroundColor: const Color(0xFF1E201E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: isSyncing
                  ? null
                  : () {
                      HapticFlow.light();
                      context.read<WearableSyncBloc>().add(const TriggerManualSyncEvent());
                    },
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(isSyncing ? 'Synchronizing Wearable Data...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : AppColors.obsidianBlack,
                foregroundColor: isDark ? Colors.black87 : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIBriefingCard(
    BuildContext context,
    dynamic insight,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2220) : const Color(0xFFF2F7F3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8BA88E).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Morning Health Briefing',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? const Color(0xFFB0CEB2) : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.summary as String,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimary,
              height: 1.4,
            ),
          ),
          if ((insight.recommendations as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recommendations:',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 6),
            for (final rec in (insight.recommendations as List))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 12,
                          color: textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutomatedHabitsCard(
    BuildContext context,
    WearableSyncSuccess state,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final summary = state.currentSummary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2024) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3238) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Habit Automation',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Deterministic',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E201E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAutomationMetricRow(
            icon: Icons.directions_walk_rounded,
            title: 'Daily Steps',
            value: '${summary.steps} steps',
            rule: 'Auto-completes at 8,000 steps',
            progress: (summary.steps / 8000.0).clamp(0.0, 1.0),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
          const Divider(height: 20),
          _buildAutomationMetricRow(
            icon: Icons.bedtime_rounded,
            title: 'Sleep Target',
            value: '${summary.sleepHours} hrs',
            rule: 'Auto-completes at 7.0 hours',
            progress: (summary.sleepHours / 7.0).clamp(0.0, 1.0),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
          const Divider(height: 20),
          _buildAutomationMetricRow(
            icon: Icons.fitness_center_rounded,
            title: 'Exercise & Workout',
            value: '${summary.exerciseMinutes} mins',
            rule: 'Auto-completes at 30 mins',
            progress: (summary.exerciseMinutes / 30.0).clamp(0.0, 1.0),
            isDark: isDark,
            textPrimary: textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationMetricRow({
    required IconData icon,
    required String title,
    required String value,
    required String rule,
    required double progress,
    required bool isDark,
    required Color textPrimary,
  }) {
    final isDone = progress >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 18, color: isDone ? const Color(0xFF10B981) : textPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDone ? const Color(0xFF10B981) : textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          rule,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 11,
            color: isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? const Color(0xFF2A2D32) : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? const Color(0xFF10B981) : AppColors.limeAccent,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevicesCard(
    BuildContext context,
    WearableSyncSuccess state,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2024) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3238) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ecosystem & Wearable Devices',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeviceItem(
            name: Platform.isIOS ? 'Apple Watch & HealthKit' : 'Wear OS & Health Connect',
            status: state.hasPermissions ? 'Active Sync' : 'Not Connected',
            icon: Icons.watch_outlined,
            isActive: state.hasPermissions,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          _buildDeviceItem(
            name: 'Garmin / Fitbit / Oura Companion Sync',
            status: 'OS Aggregated',
            icon: Icons.cloud_done_outlined,
            isActive: true,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem({
    required String name,
    required String status,
    required IconData icon,
    required bool isActive,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 18, color: textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF10B981) : textMuted,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
