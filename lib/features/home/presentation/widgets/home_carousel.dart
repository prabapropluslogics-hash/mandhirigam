import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import 'carousel_indicator.dart';

/// Swipeable Home carousel with an optional calm auto-advance.
///
/// Auto-advance runs only while the carousel is on screen (visible tab and
/// top route), the app is resumed, the user is not dragging, and the platform
/// has not asked to reduce motion. Give it a new [Key] when the items change.
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.autoPlay = true,
    this.heightFactor = 0.62,
    this.minHeight = 210,
    this.maxHeight = 300,
    this.textScaleAllowance = 120,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool autoPlay;

  /// Slide height as a fraction of slide width, clamped to
  /// [minHeight]..[maxHeight] (and to half the screen height).
  final double heightFactor;
  final double minHeight;
  final double maxHeight;

  /// Extra height per unit of text scale above 1.0, so larger accessibility
  /// text does not clip.
  final double textScaleAllowance;

  static const Duration interval = Duration(seconds: 3);
  static const Duration transition = Duration(milliseconds: 900);

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel>
    with WidgetsBindingObserver {
  static const double _viewportFraction = 0.9;
  static const double _inactiveScale = 0.95;

  /// Pages are virtual and wrap around; starting far from zero lets the
  /// carousel always move forward and still be swiped backwards.
  static const int _loopOrigin = 1000;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
    initialPage: _loops ? widget.itemCount * _loopOrigin : 0,
  );
  final ValueNotifier<int> _activeIndex = ValueNotifier<int>(0);

  Timer? _timer;
  bool _onScreen = true;
  bool _appActive = true;
  bool _userDragging = false;
  bool _reduceMotion = false;

  int get _count => widget.itemCount;
  bool get _loops => _count > 1;

  bool get _shouldAutoPlay =>
      widget.autoPlay &&
      _loops &&
      _onScreen &&
      _appActive &&
      !_userDragging &&
      !_reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onScreen = TickerMode.of(context) && Visibility.of(context);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncAutoPlay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncAutoPlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoPlay();
    _controller.dispose();
    _activeIndex.dispose();
    super.dispose();
  }

  void _syncAutoPlay() {
    if (_shouldAutoPlay) {
      _timer ??= Timer.periodic(HomeCarousel.interval, (_) => _advance());
    } else {
      _stopAutoPlay();
    }
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    _controller.nextPage(
      duration: HomeCarousel.transition,
      curve: Curves.easeInOutCubic,
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDragging = true;
      _stopAutoPlay();
    } else if (notification is ScrollEndNotification && _userDragging) {
      _userDragging = false;
      _syncAutoPlay();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double slideWidth = constraints.maxWidth * _viewportFraction;
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final double maxHeight = (MediaQuery.sizeOf(context).height * 0.5)
            .clamp(widget.minHeight, widget.maxHeight);
        final double height = (slideWidth * widget.heightFactor)
                .clamp(widget.minHeight, maxHeight) +
            math.max(0, textScale - 1) * widget.textScaleAllowance;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _loops ? null : _count,
                  onPageChanged: (int page) =>
                      _activeIndex.value = page % _count,
                  itemBuilder: (BuildContext context, int page) {
                    return _CarouselSlide(
                      controller: _controller,
                      page: page,
                      inactiveScale: _inactiveScale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: RepaintBoundary(
                          child: widget.itemBuilder(context, page % _count),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_loops) ...[
              const SizedBox(height: AppSpacing.md),
              ValueListenableBuilder<int>(
                valueListenable: _activeIndex,
                builder: (BuildContext context, int index, _) {
                  return CarouselIndicator(count: _count, activeIndex: index);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Slightly shrinks slides that are away from the centre position.
class _CarouselSlide extends StatelessWidget {
  const _CarouselSlide({
    required this.controller,
    required this.page,
    required this.inactiveScale,
    required this.child,
  });

  final PageController controller;
  final int page;
  final double inactiveScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (BuildContext context, Widget? child) {
        double current = controller.initialPage.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          current = controller.page ?? current;
        }
        final double distance = (current - page).abs().clamp(0.0, 1.0);
        return Transform.scale(
          scale: 1 - distance * (1 - inactiveScale),
          child: child,
        );
      },
    );
  }
}
