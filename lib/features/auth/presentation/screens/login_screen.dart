import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../state/auth_controller.dart';
import '../../../startup/presentation/widgets/splash_brand.dart';
import '../../../startup/presentation/widgets/splash_intro.dart';
import '../widgets/google_continue_button.dart';
import '../widgets/login_backdrop.dart';
import '../widgets/login_hero.dart';

/// Google sign-in, opened on top of the screen that needs it. Pops `true`
/// once signed in and `false` when the user backs out or cancels Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.message});

  final String? message;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Content column width cap for tablets / wide portrait windows.
  static const double _maxContentWidth = 460;

  /// Landscape windows at least this wide put the illustration beside the
  /// actions instead of above them.
  static const double _wideMinWidth = 600;

  static const double _minHeroHeight = 150;
  static const double _maxHeroHeight = 460;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final AuthController auth = context.read<AuthController>();
      if (auth.isAuthenticated) {
        Navigator.of(context).pop(true);
        return;
      }
      auth.clearError();
    });
  }

  Future<void> _signIn() async {
    final AuthController auth = context.read<AuthController>();
    final SignInOutcome outcome = await auth.signInWithGoogle();
    if (!mounted) return;
    switch (outcome) {
      case SignInOutcome.signedIn:
        final String name = auth.user?.name ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(name.isEmpty ? 'Signed in.' : 'Signed in as $name.'),
          ),
        );
        Navigator.of(context).pop(true);
      case SignInOutcome.cancelled:
        Navigator.of(context).pop(false);
      case SignInOutcome.failed:
      case SignInOutcome.busy:
        break;
    }
  }

  /// Height left for the illustration once the brand block and actions are
  /// accounted for; text-dependent parts grow with the user's text scale.
  double _portraitHeroHeight(double available, {required bool hasError}) {
    final double textScale = MediaQuery.textScalerOf(context).scale(100) / 100;
    double reserved = 300 + 100 * textScale;
    if (hasError) reserved += 40 + 50 * textScale;
    return (available - reserved).clamp(_minHeroHeight, _maxHeroHeight);
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final String? message = widget.message;
    final bool busy = auth.signingIn;
    final String? error = auth.errorMessage;

    final Widget backButton = Align(
      alignment: Alignment.centerLeft,
      child: AppIconButton(
        icon: AppIcons.back,
        tooltip: 'Back',
        color: AppColors.splashTagline,
        onPressed: busy ? null : () => Navigator.of(context).maybePop(false),
      ),
    );

    final Widget actions = _LoginActions(
      supportingText: message != null && message.isNotEmpty
          ? message
          : 'Sign in with Google to read books, buy titles, '
              'and keep your library on every device.',
      error: error,
      busy: busy,
      onGoogle: _signIn,
      onGuest: busy ? null : () => Navigator.of(context).maybePop(false),
    );

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const LoginBackdrop(),
            SafeArea(
              child: SplashIntro(
                builder: (BuildContext context, Animation<double> progress) {
                  return LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final bool wide = box.maxWidth > box.maxHeight &&
                          box.maxWidth >= _wideMinWidth;
                      return wide
                          ? _buildWide(box, progress, backButton, actions)
                          : _buildPortrait(
                              box,
                              progress,
                              backButton,
                              actions,
                              hasError: error != null,
                            );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(
    BoxConstraints box,
    Animation<double> progress,
    Widget backButton,
    Widget actions, {
    required bool hasError,
  }) {
    const double vertical = AppSpacing.sm;
    final double horizontal = math.max(
      AppSpacing.pageHorizontal,
      (box.maxWidth - _maxContentWidth) / 2,
    );
    final double minHeight = box.maxHeight - vertical * 2;
    final double heroHeight =
        _portraitHeroHeight(minHeight, hasError: hasError);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                backButton,
                SplashReveal(
                  progress: progress,
                  begin: 0.05,
                  end: 0.45,
                  child: const _LoginBrand(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SplashReveal(
                  progress: progress,
                  begin: 0,
                  end: 0.55,
                  scaleFrom: 0.98,
                  child: LoginHero(
                    height: heroHeight,
                    maxWidth: box.maxWidth - horizontal * 2,
                  ),
                ),
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _buildWide(
    BoxConstraints box,
    Animation<double> progress,
    Widget backButton,
    Widget actions,
  ) {
    const EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.pageHorizontal,
      vertical: AppSpacing.sm,
    );
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: SplashReveal(
                  progress: progress,
                  begin: 0,
                  end: 0.55,
                  scaleFrom: 0.98,
                  child: LoginHero(
                    height: box.maxHeight,
                    maxWidth: box.maxWidth / 2,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Padding(padding: padding, child: backButton),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SplashReveal(
                      progress: progress,
                      begin: 0.05,
                      end: 0.45,
                      child: const _LoginBrand(),
                    ),
                    const AppGap.xl(),
                    actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Wordmark, ornament and tagline — the same pieces the splash uses.
class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    final double scale =
        (MediaQuery.sizeOf(context).shortestSide / 390).clamp(0.85, 1.15);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SplashTitle(fontSize: 28 * scale),
        const AppGap.sm(),
        SplashOrnament(lineWidth: 36 * scale),
        const AppGap.sm(),
        const SplashTagline(),
      ],
    );
  }
}

class _LoginActions extends StatelessWidget {
  const _LoginActions({
    required this.supportingText,
    required this.error,
    required this.busy,
    required this.onGoogle,
    required this.onGuest,
  });

  final String supportingText;
  final String? error;
  final bool busy;
  final VoidCallback onGoogle;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final String? error = this.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          supportingText,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall(context).copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
        const AppGap.lg(),
        if (error != null) ...[
          _ErrorPanel(message: error),
          const AppGap.md(),
        ],
        GoogleContinueButton(
          key: const Key('google-sign-in'),
          label: error == null ? 'Continue with Google' : 'Try again',
          isLoading: busy,
          onPressed: onGoogle,
        ),
        const AppGap.md(),
        AppOutlinedButton(
          label: 'Continue as Guest',
          size: AppButtonSize.large,
          onPressed: onGuest,
          backgroundColor: AppColors.surfaceDark.withOpacity(0.35),
          foregroundColor: AppColors.splashTagline,
          borderColor: AppColors.brandPrimary.withOpacity(0.5),
        ),
        const AppGap.md(),
        Text(
          busy
              ? 'Waiting for Google…'
              : 'We use your Google name, email and photo only to '
                  'set up your account.',
          textAlign: TextAlign.center,
          style: AppTypography.caption(context).copyWith(
            color: AppColors.textSecondaryDark.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  bool get _isNetwork => message.toLowerCase().contains('connection');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: AppInsets.md,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.85),
          borderRadius: AppRadii.containerBorder,
          border: Border.all(color: AppColors.error.withOpacity(0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _isNetwork ? AppIcons.offline : AppIcons.error,
              size: AppSizes.iconMd,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall(context).copyWith(
                  color: AppColors.splashTagline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
