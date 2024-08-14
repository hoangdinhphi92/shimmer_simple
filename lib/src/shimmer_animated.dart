import 'package:flutter/material.dart';
import 'package:shimmer_simple/src/shimmer_container.dart';

class ShimmerAnimated extends StatefulWidget {
  const ShimmerAnimated({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShimmerAnimated> createState() => _ShimmerAnimatedState();
}

class _ShimmerAnimatedState extends State<ShimmerAnimated> {
  Listenable? _shimmerChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shimmerChanges != null) {
      _shimmerChanges!.removeListener(_onShimmerChange);
    }
    _shimmerChanges = ShimmerContainer.of(context)?.shimmerChanges;
    if (_shimmerChanges != null) {
      _shimmerChanges!.addListener(_onShimmerChange);
    }
  }

  @override
  void dispose() {
    _shimmerChanges?.removeListener(_onShimmerChange);
    super.dispose();
  }

  void _onShimmerChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    // Collect ancestor shimmer info.
    final shimmer = ShimmerContainer.of(context)!;
    if (!shimmer.isSized || renderBox == null) {
      // The ancestor Shimmer widget has not laid
      // itself out yet. Return an empty box.
      return const SizedBox.shrink();
    }
    final gradient = shimmer.gradient;
    final shaderRectWithinShimmer = shimmer.getDescendantShaderRect(
      descendant: renderBox,
    );

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return gradient.createShader(shaderRectWithinShimmer);
      },
      child: widget.child,
    );
  }

  Rect scaleRect(Rect rect, double scaleFactor) {
    // Find the center of the Rect
    final Offset center = rect.center;

    // Calculate the new width and height
    final double newWidth = rect.width * scaleFactor;
    final double newHeight = rect.height * scaleFactor;

    // Calculate the top-left position of the new Rect so that it's centered
    final double left = center.dx - (newWidth / 2);
    final double top = center.dy - (newHeight / 2);

    // Return the new scaled Rect
    return Rect.fromLTWH(left, top, newWidth, newHeight);
  }
}
