import 'package:flutter/scheduler.dart';

/// Merekam [FrameTiming] selama benchmark berlangsung.
///
/// Dipasang sekali di `main()` melalui
/// `WidgetsBinding.instance.addTimingsCallback(...)`, sehingga setiap frame
/// (termasuk frame yang dibangun oleh `ListView.builder`) dapat diukur.
class PerformanceMetrics {
  PerformanceMetrics._();

  static final PerformanceMetrics instance = PerformanceMetrics._();

  final List<FrameTiming> _samples = <FrameTiming>[];
  bool _recording = false;

  bool get isRecording => _recording;

  void startRecording() {
    _samples.clear();
    _recording = true;
  }

  void stopRecording() {
    _recording = false;
  }

  void clear() {
    _samples.clear();
    _recording = false;
  }

  /// Callback untuk [WidgetsBinding.addTimingsCallback].
  void recordTimings(List<FrameTiming> timings) {
    if (!_recording) return;
    _samples.addAll(timings);
  }

  List<FrameTiming> get samples => List<FrameTiming>.unmodifiable(_samples);

  PerformanceSummary get summary => PerformanceSummary.fromSamples(_samples);
}

/// Ringkasan metrik frame yang diukur dari [FrameTiming].
///
/// Ambang jank memakai budget frame 60 FPS (16,67 ms) sesuai modul Week 11.
class PerformanceSummary {
  const PerformanceSummary({
    required this.totalFrames,
    required this.jankyFrames,
    required this.jankPercent,
    required this.averageFrameMs,
    required this.p95FrameMs,
    required this.worstFrameMs,
    required this.averageBuildMs,
    required this.averageRasterMs,
  });

  factory PerformanceSummary.fromSamples(List<FrameTiming> samples) {
    if (samples.isEmpty) {
      return const PerformanceSummary(
        totalFrames: 0,
        jankyFrames: 0,
        jankPercent: 0,
        averageFrameMs: 0,
        p95FrameMs: 0,
        worstFrameMs: 0,
        averageBuildMs: 0,
        averageRasterMs: 0,
      );
    }

    const budgetMs = 1000.0 / 60.0; // 16,67 ms untuk 60 FPS
    final totalSpans = <double>[];
    final builds = <double>[];
    final rasters = <double>[];
    var janky = 0;

    for (final timing in samples) {
      final total = timing.totalSpan.inMicroseconds / 1000.0;
      final build = timing.buildDuration.inMicroseconds / 1000.0;
      final raster = timing.rasterDuration.inMicroseconds / 1000.0;
      totalSpans.add(total);
      builds.add(build);
      rasters.add(raster);
      if (total > budgetMs) janky++;
    }

    totalSpans.sort();
    // Nearest-rank P95: index = ceil(0.95 * n) - 1.
    final p95Index = ((totalSpans.length * 0.95).ceil() - 1).clamp(
      0,
      totalSpans.length - 1,
    );

    double average(List<double> values) =>
        values.reduce((a, b) => a + b) / values.length;

    return PerformanceSummary(
      totalFrames: samples.length,
      jankyFrames: janky,
      jankPercent: janky / samples.length * 100,
      averageFrameMs: average(totalSpans),
      p95FrameMs: totalSpans[p95Index],
      worstFrameMs: totalSpans.last,
      averageBuildMs: average(builds),
      averageRasterMs: average(rasters),
    );
  }

  final int totalFrames;
  final int jankyFrames;
  final double jankPercent;
  final double averageFrameMs;
  final double p95FrameMs;
  final double worstFrameMs;
  final double averageBuildMs;
  final double averageRasterMs;
}
