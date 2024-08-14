import 'dart:math';

import 'package:flutter/material.dart';

class ShimmerContainer extends StatefulWidget {
  static ShimmerContainerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerContainerState>();
  }

  final Gradient gradient;
  final Widget child;

  const ShimmerContainer({
    super.key,
    required this.gradient,
    required this.child,
  });

  factory ShimmerContainer.linear({
    Alignment begin = const Alignment(-1.0, -0.3),
    Alignment end = const Alignment(1.0, 0.3),
    List<Color> colors = const [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    List<double>? stops = const [
      0.1,
      0.3,
      0.4,
    ],
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
    required Widget child,
  }) {
    return ShimmerContainer(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: colors,
        stops: stops,
        tileMode: tileMode,
        transform: transform,
      ),
      child: child,
    );
  }

  factory ShimmerContainer.radial({
    Alignment center = Alignment.center,
    double radius = 0.5,
    List<Color> colors = const [
      Color(0xFFEBEBF4),
      Color(0xFFF4F4F4),
      Color(0xFFEBEBF4),
    ],
    List<double>? stops = const [
      0.1,
      0.3,
      0.4,
    ],
    TileMode tileMode = TileMode.clamp,
    AlignmentGeometry? focal,
    double focalRadius = 0.0,
    GradientTransform? transform,
    required Widget child,
  }) {
    return ShimmerContainer(
      gradient: RadialGradient(
        center: center,
        radius: radius,
        colors: colors,
        stops: stops,
        tileMode: tileMode,
        focal: focal,
        focalRadius: focalRadius,
        transform: transform,
      ),
      child: child,
    );
  }

  @override
  State<ShimmerContainer> createState() => ShimmerContainerState();
}

class ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late _ShimmerListenable _shimmerChanges;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerChanges = _ShimmerListenable(
      onListenableChanged: _onListenableChanged,
    );

    _shimmerController = AnimationController.unbounded(vsync: this);
    _shimmerController.addListener(_onShimmerChanged);
  }

  void _repeat() {
    _shimmerController.repeat(
      min: -0.5,
      max: 1.5,
      period: const Duration(milliseconds: 1000),
    );
  }

  void _onListenableChanged(bool hasListeners) {
    if (hasListeners) {
      _repeat();
    } else {
      _shimmerController.stop();
    }
  }

  void _onShimmerChanged() {
    _shimmerChanges.invalidate();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Gradient get gradient => switch (widget.gradient) {
        final linearGradient when linearGradient is LinearGradient =>
          LinearGradient(
            colors: linearGradient.colors,
            stops: linearGradient.stops,
            begin: linearGradient.begin,
            end: linearGradient.end,
            transform: _SlidingGradientTransform(
              slidePercent: _shimmerController.value,
            ),
          ),
        final radialGradient when radialGradient is RadialGradient =>
          RadialGradient(
            center: radialGradient.center,
            radius: radialGradient.radius,
            colors: radialGradient.colors,
            stops: radialGradient.stops?.translate(_shimmerController.value),
            focal: radialGradient.focal,
            focalRadius: radialGradient.focalRadius,
          ),
        _ => throw UnimplementedError(
            "Not support ${widget.gradient.runtimeType}. We current only support LinearGradient and RadialGradient.",
          ),
      };

  bool get isSized =>
      (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject() as RenderBox).size;

  Offset getDescendantOffset({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerBox = context.findRenderObject() as RenderBox?;
    return descendant.localToGlobal(offset, ancestor: shimmerBox);
  }

  Rect getDescendantShaderRect({
    required RenderBox descendant,
    Offset offset = Offset.zero,
  }) {
    final shimmerSize = size;

    final offsetWithinShimmer = getDescendantOffset(
      descendant: descendant,
      offset: offset,
    );

    if (widget.gradient is LinearGradient) {
      return Rect.fromLTWH(
        -offsetWithinShimmer.dx,
        -offsetWithinShimmer.dy,
        shimmerSize.width,
        shimmerSize.height,
      );
    } else if (widget.gradient is RadialGradient) {
      final center = Offset(
        shimmerSize.width / 2 - offsetWithinShimmer.dx,
        shimmerSize.height / 2 - offsetWithinShimmer.dy,
      );
      final size = max(shimmerSize.width, shimmerSize.height);
      return Rect.fromLTWH(
        center.dx - (size / 2),
        center.dy - (size / 2),
        size,
        size,
      );
    }

    throw UnimplementedError(
      "Not support ${widget.gradient.runtimeType}. We current only support LinearGradient and RadialGradient.",
    );
  }

  Listenable get shimmerChanges => _shimmerChanges;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

extension on List<double> {
  List<double> translate(double translate) {
    return map((e) => e + translate).toList();
  }
}

class _ShimmerListenable extends ChangeNotifier {
  final ValueChanged<bool> onListenableChanged;

  bool _isHasListeners = false;

  set isHasListeners(bool value) {
    if (_isHasListeners != value) {
      _isHasListeners = value;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => onListenableChanged(value),
      );
    }
  }

  _ShimmerListenable({required this.onListenableChanged});

  void invalidate() => notifyListeners();

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);

    isHasListeners = hasListeners;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);

    isHasListeners = hasListeners;
  }
}
