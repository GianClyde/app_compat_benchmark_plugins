import 'dart:async';

import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_perf_monitor/flutter_perf_monitor.dart';

/// Expects PerformanceRunContext handles to contain:
/// - scrollHandle: ScrollController
/// - navHandle: BuildContext
/// - tickerHandle: TickerProvider
class FlutterPerfMonitorRunner implements PerformanceRunner {
  final Duration sampleInterval;
  final Duration settleDelay;

  FlutterPerfMonitorRunner({
    this.sampleInterval = const Duration(milliseconds: 100),
    this.settleDelay = const Duration(milliseconds: 500),
  });

  @override
  Future<List<BenchmarkStepResult>> runAllSteps(
    PerformanceRunContext context,
  ) async {
    FlutterPerfMonitor.initialize();

    final results = <BenchmarkStepResult>[];

    // idle
    results.add(
      await _runStep(
        step: BenchmarkStepType.idle,
        action: () async => Future.delayed(const Duration(seconds: 2)),
      ),
    );

    // scroll
    final scroll = context.scrollHandle;
    if (scroll is ScrollController) {
      results.add(
        await _runStep(
          step: BenchmarkStepType.scroll,
          action: () => _scrollTest(scroll),
        ),
      );
    } else {
      // If not provided, still return a step with 0s (or skip; your choice)
      results.add(_emptyStep(BenchmarkStepType.scroll));
    }

    // navigation
    final nav = context.navHandle;
    if (nav is BuildContext) {
      results.add(
        await _runStep(
          step: BenchmarkStepType.navigation,
          action: () => _navigationTest(nav),
        ),
      );
    } else {
      results.add(_emptyStep(BenchmarkStepType.navigation));
    }

    // animation
    final animCtx = context.navHandle;
    final vsync = context.tickerHandle;
    if (animCtx is BuildContext && vsync is TickerProvider) {
      results.add(
        await _runStep(
          step: BenchmarkStepType.animation,
          action: () => _animationStressTest(animCtx, vsync),
        ),
      );
    } else {
      results.add(_emptyStep(BenchmarkStepType.animation));
    }

    return results;
  }

  BenchmarkStepResult _emptyStep(BenchmarkStepType type) => BenchmarkStepResult(
    type: type,
    fps: 0,
    frameTimeMs: 0,
    cpuUsagePercent: 0,
    memoryKb: 0,
  );

  Future<BenchmarkStepResult> _runStep({
    required BenchmarkStepType step,
    required Future<void> Function() action,
  }) async {
    FlutterPerfMonitor.startMonitoring();
    final samples = <PerformanceMetrics>[];

    final timer = Timer.periodic(sampleInterval, (_) {
      samples.add(FlutterPerfMonitor.getCurrentMetrics());
    });

    await action();
    await Future.delayed(settleDelay);

    timer.cancel();
    FlutterPerfMonitor.stopMonitoring();

    if (samples.isEmpty) {
      return BenchmarkStepResult(
        type: step,
        fps: 0,
        frameTimeMs: 0,
        cpuUsagePercent: 0,
        memoryKb: 0,
      );
    }

    final avgFps = _avg(samples.map((m) => m.fps));
    final avgCpu = _avg(samples.map((m) => m.cpuUsage));
    final avgMemory = _avg(samples.map((m) => (m.memoryUsage)));
    final avgFrameTime = _avg(samples.map((m) => m.frameTime));

    return BenchmarkStepResult(
      type: step,
      fps: avgFps,
      frameTimeMs: avgFrameTime,
      cpuUsagePercent: avgCpu,
      memoryKb: avgMemory,
    );
  }

  double _avg(Iterable<num> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;

    double sum = 0;
    for (final v in list) {
      sum += v.toDouble();
    }
    return sum / list.length;
  }

  Future<void> _scrollTest(ScrollController controller) async {
    if (!controller.hasClients) return;

    final max = controller.position.maxScrollExtent;
    for (int i = 0; i < 4; i++) {
      await controller.animateTo(
        max,
        duration: const Duration(milliseconds: 700),
        curve: Curves.linear,
      );
      await controller.animateTo(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.linear,
      );
    }
  }

  Future<void> _navigationTest(BuildContext context) async {
    for (int i = 0; i < 3; i++) {
      final route = MaterialPageRoute(builder: (_) => const _BenchmarkPage());
      Navigator.of(context).push(route);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _animationStressTest(
    BuildContext context,
    TickerProvider vsync,
  ) async {
    final completer = Completer<void>();
    late final AnimationController controller;

    final overlay = OverlayEntry(
      builder: (_) {
        controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 900),
        )..repeat(reverse: true);

        final animation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        );

        int frames = 0;
        void listener() {
          frames++;
          if (frames >= 400) {
            controller.removeListener(listener);
            controller.dispose();
            completer.complete();
          }
        }

        controller.addListener(listener);

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(14, (index) {
              return AnimatedBuilder(
                animation: animation,
                builder: (_, __) {
                  final angle = animation.value * 2 * 3.14159 * (index + 1.3);
                  final scaleFactor = 0.5 + 0.7 * animation.value;
                  final opacity =
                      0.4 + 0.6 * (1 - (animation.value - 0.5).abs() * 2);
                  final size = 30.0 + index * 18;

                  return Transform.rotate(
                    angle: index.isEven ? angle : -angle * 1.4,
                    child: Transform.scale(
                      scale: scaleFactor,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              index.isEven ? 12 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );

    Overlay.of(context).insert(overlay);
    await completer.future;
    overlay.remove();
  }
}

/// Minimal route for navigation benchmark.
/// Keep it simple to avoid app-specific dependencies.
class _BenchmarkPage extends StatelessWidget {
  const _BenchmarkPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Benchmark Route")),
      body: ListView.builder(
        itemCount: 80,
        itemBuilder: (_, i) => ListTile(title: Text("Sample Item $i")),
      ),
    );
  }
}
