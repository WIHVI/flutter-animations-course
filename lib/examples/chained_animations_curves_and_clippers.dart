import 'package:flutter/material.dart';
import 'dart:math' show pi;

enum CircleSide { left, right }

extension ToPath on CircleSide {
  Path toPath(Size size) {
    Path path = Path();

    late Offset offset;
    late bool clockwise;

    switch (this) {
      case CircleSide.left:
        path.moveTo(size.width, 0);
        offset = Offset(size.width, size.height);
        clockwise = false;
        break;
      case CircleSide.right:
        offset = Offset(0, size.height);
        clockwise = true;
        break;
    }

    path.arcToPoint(
      offset,
      radius: Radius.elliptical(size.width / 2, size.height / 2),
      clockwise: clockwise,
    );

    path.close();

    return path;
  }
}

class HalfCircleClipper extends CustomClipper<Path> {
  final CircleSide side;

  const HalfCircleClipper({super.reclip, required this.side});

  @override
  Path getClip(Size size) => side.toPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

extension on VoidCallback {
  Future<void> delayed(Duration duration) => Future.delayed(duration, this);
}

class ChainedAnimationsCurvesAndClippers extends StatefulWidget {
  const ChainedAnimationsCurvesAndClippers({super.key});

  @override
  State<ChainedAnimationsCurvesAndClippers> createState() =>
      _ChainedAnimationsCurvesAndClippersState();
}

class _ChainedAnimationsCurvesAndClippersState
    extends State<ChainedAnimationsCurvesAndClippers>
    with TickerProviderStateMixin {
  late AnimationController _counterClockwiseRotationController;
  late Animation<double> _counterClockwiseRotationAnimation;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    _counterClockwiseRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _counterClockwiseRotationAnimation = Tween<double>(
      begin: 0,
      end: -(pi / 2),
    ).animate(
      CurvedAnimation(
        parent: _counterClockwiseRotationController,
        curve: Curves.bounceOut,
      ),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _flipAnimation = Tween<double>(
      begin: 0,
      end: pi,
    ).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.bounceOut,
      ),
    );

    _counterClockwiseRotationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flipAnimation = Tween<double>(
          begin: _flipAnimation.value,
          end: _flipAnimation.value + pi,
        ).animate(
          CurvedAnimation(
            parent: _flipController,
            curve: Curves.bounceOut,
          ),
        );

        _flipController
          ..reset()
          ..forward();
      }
    });

    _flipController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _counterClockwiseRotationAnimation = Tween<double>(
            begin: _counterClockwiseRotationAnimation.value,
            end: _counterClockwiseRotationAnimation.value + -(pi / 2.0),
          ).animate(
            CurvedAnimation(
              parent: _counterClockwiseRotationController,
              curve: Curves.bounceOut,
            ),
          );
          _counterClockwiseRotationController
            ..reset()
            ..forward();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _counterClockwiseRotationController.dispose();
    _flipController.dispose();
    _flipController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _counterClockwiseRotationController
      ..reset()
      ..forward.delayed(
        const Duration(
          seconds: 1,
        ),
      );

    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
            animation: _counterClockwiseRotationAnimation,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_counterClockwiseRotationAnimation.value),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                        animation: _flipController,
                        builder: (context, child) {
                          return Transform(
                            alignment: Alignment.centerRight,
                            transform: Matrix4.identity()
                              ..rotateY(
                                _flipAnimation.value,
                              ),
                            child: ClipPath(
                              clipper: const HalfCircleClipper(
                                  side: CircleSide.left),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }),
                    AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          return Transform(
                            alignment: Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..rotateY(
                                _flipAnimation.value,
                              ),
                            child: ClipPath(
                              clipper: const HalfCircleClipper(
                                  side: CircleSide.right),
                              child: Container(
                                width: 100,
                                height: 100,
                                color: Colors.yellow,
                              ),
                            ),
                          );
                        })
                  ],
                ),
              );
            }),
      ),
    );
  }
}
