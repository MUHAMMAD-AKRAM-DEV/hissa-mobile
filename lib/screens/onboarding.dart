// ============================================================
//  lib/screens/onboarding.dart  —  Splash / intro (rotating).
//  Goes in:  hissa_mobile/lib/screens/onboarding.dart   (replace all)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

const _mine = {6, 7, 8, 11, 12, 13, 16};

const _slides = [
  ['Own a slice of\nreal estate',
    'Invest in vetted properties across Pakistan from as little as PKR 5,000.'],
  ['Earn rental\nincome',
    'Your share of the rent is paid into your wallet every month, automatically.'],
  ['Exit whenever\nyou want',
    'Sell your shares on the in-app marketplace — no waiting years to cash out.'],
];

class SplashScreen extends StatefulWidget {
  final VoidCallback onStart;
  const SplashScreen({super.key, required this.onStart});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _slide = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      setState(() => _slide = (_slide + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brand, c.brandDeep],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: c.gold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('Hissa',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5)),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Center(child: _ShareGrid()),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Column(
                            key: ValueKey(_slide),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 78,
                                child: Text(_slides[_slide][0],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                        letterSpacing: -0.6)),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 48,
                                child: Text(_slides[_slide][1],
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 15, height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: List.generate(_slides.length, (i) {
                            final on = i == _slide;
                            return GestureDetector(
                              onTap: () => setState(() => _slide = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 7),
                                width: on ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: on ? c.gold : Colors.white30,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.gold,
                              foregroundColor: const Color(0xFF3A2604),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Get started',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: widget.onStart,
                            child: const Text('I already have an account',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareGrid extends StatelessWidget {
  const _ShareGrid();

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return SizedBox(
      width: 170,
      height: 170,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
        ),
        itemCount: 25,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: _mine.contains(i) ? c.gold : Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}