import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/features/splash/presentation/pages/app_shell.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
    final borderColor = isDark
        ? const Color(0xff424842).withValues(alpha: 0.35)
        : const Color(0xffdbdad7).withValues(alpha: 0.8);
    final textColor = isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f);
    final subtextColor = isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushReplacement(
            AppPageRoute(page: const AppShell()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: isDark ? const Color(0xff292a28) : const Color(0xffefeeeb),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
              ),
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: GoogleFonts.hankenGrotesk(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final loadingMessage = state is AuthLoading ? state.message : null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Brand Icon with pulsing aura
                    StaggeredEntrance(
                      index: 0,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = 0.94 + (_pulseController.value * 0.06);
                          return SizedBox(
                            width: 110,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100 * pulse,
                                  height: 100 * pulse,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
                                  ),
                                ),
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: isDark ? 0.25 : 0.18),
                                        blurRadius: 20 * pulse,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Title & Tagline
                    StaggeredEntrance(
                      index: 1,
                      child: Text(
                        'habitrak',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StaggeredEntrance(
                      index: 2,
                      child: Text(
                        'Build consistent daily habits with mindful clarity',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: subtextColor,
                          height: 1.35,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Feature highlights pill card
                    StaggeredEntrance(
                      index: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              icon: Icons.cloud_done_outlined,
                              title: 'Seamless Cloud Sync',
                              subtitle: 'Your habits & streaks backed up to Firebase',
                              primary: primary,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: borderColor, height: 1),
                            ),
                            _buildFeatureRow(
                              icon: Icons.bolt_outlined,
                              title: 'Streak & Mindful Analytics',
                              subtitle: 'Real-time progress tracking across all devices',
                              primary: primary,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: borderColor, height: 1),
                            ),
                            _buildFeatureRow(
                              icon: Icons.shield_outlined,
                              title: 'Private & Secure Account',
                              subtitle: 'Isolated database permissions per user profile',
                              primary: primary,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Sign-in buttons section
                    StaggeredEntrance(
                      index: 4,
                      child: isLoading
                          ? Column(
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  loadingMessage ?? 'Connecting...',
                                  style: GoogleFonts.hankenGrotesk(
                                    color: subtextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Google Sign-In Button
                                PressableScale(
                                  onTap: () => context.read<AuthCubit>().loginWithGoogle(),
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xff292a28) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? primary.withValues(alpha: 0.3)
                                            : const Color(0xffdcdbd8),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withValues(alpha: isDark ? 0.12 : 0.10),
                                          blurRadius: 14,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildGoogleIcon(),
                                        const SizedBox(width: 14),
                                        Text(
                                          'Continue with Google',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Guest Mode Button
                                PressableScale(
                                  onTap: () => context.read<AuthCubit>().continueAsGuest(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: subtextColor.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Continue as Guest',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: subtextColor,
                                            decoration: TextDecoration.underline,
                                            decorationColor: subtextColor.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Footer notes
                    StaggeredEntrance(
                      index: 5,
                      child: Text(
                        'By continuing, you agree to sync your habit data securely with Firebase Cloud Storage.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: subtextColor.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primary,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

/// Precise vector painter for Google 'G' icon with official brand colors
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Red (top)
    paint.color = const Color(0xffea4335);
    final pathRed = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * math.cos(math.pi * 1.25), cy - r * math.sin(math.pi * 1.25))
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(pathRed, paint);

    // Yellow (left)
    paint.color = const Color(0xfffbbc05);
    final pathYellow = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * math.cos(math.pi * 0.25), cy - r * math.sin(math.pi * 0.25))
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi * 1.25,
        math.pi * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(pathYellow, paint);

    // Green (bottom)
    paint.color = const Color(0xff34a853);
    final pathGreen = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * math.cos(math.pi * 0.25), cy + r * math.sin(math.pi * 0.25))
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        math.pi * 0.25,
        math.pi * 0.5,
        false,
      )
      ..close();
    canvas.drawPath(pathGreen, paint);

    // Blue (right)
    paint.color = const Color(0xff4285f4);
    final pathBlue = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0,
        math.pi * 0.25,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(pathBlue, paint);

    // Blue horizontal bar
    final barRect = Rect.fromLTWH(cx - 1, cy - (h * 0.18) / 2, r + 1, h * 0.18);
    canvas.drawRect(barRect, paint);

    // Cutout center
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..blendMode = BlendMode.dstOut;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, cutoutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
