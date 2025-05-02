import 'package:flutter/material.dart';

void showCustomToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);

  // Create an animation controller
  final controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: overlay,
  );

  // Create scale animation for the "pop" effect
  final scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ),
  );

  // Create opacity animation for fade in/out
  final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ),
  );

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 30,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Opacity(
              opacity: opacityAnimation.value,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF48116A),
                          Color(0xFFC22054),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC22054).withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  // Insert overlay
  overlay.insert(overlayEntry);

  // Start the appearing animation
  controller.forward();

  // Set up the disappearing animation after delay
  Future.delayed(const Duration(seconds: 2)).then((_) {
    // Reverse the animation for smooth exit
    controller.reverse().then((_) {
      overlayEntry.remove();
      controller.dispose();
    });
  });
}
