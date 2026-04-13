

import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )
      ..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE186), // 밝은 옐로우
            Color(0xFFFFEDB9), // 크림톤
            Color(0xFFFFDAD6), // 살짝 핑크톤
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 배경을 투명하게
        body: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/images/b_read.png',
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}