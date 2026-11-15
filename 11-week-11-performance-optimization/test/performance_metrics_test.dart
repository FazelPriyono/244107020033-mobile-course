import 'dart:ui' show FrameTiming;

import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/core/performance_metrics.dart';

FrameTiming buildTiming({required int buildUs, required int rasterUs}) {
  const vsyncStart = 0;
  const buildStart = 1000;
  final buildFinish = buildStart + buildUs;
  final rasterStart = buildFinish + 100;
  final rasterFinish = rasterStart + rasterUs;
  return FrameTiming(
    vsyncStart: vsyncStart,
    buildStart: buildStart,
    buildFinish: buildFinish,
    rasterStart: rasterStart,
    rasterFinish: rasterFinish,
    rasterFinishWallTime: rasterFinish,
  );
}

void main() {
  group('PerformanceSummary', () {
    test('mengembalikan nol untuk daftar sampel kosong', () {
      final summary = PerformanceSummary.fromSamples(const <FrameTiming>[]);

      expect(summary.totalFrames, 0);
      expect(summary.jankyFrames, 0);
      expect(summary.jankPercent, 0);
      expect(summary.averageFrameMs, 0);
      expect(summary.p95FrameMs, 0);
      expect(summary.worstFrameMs, 0);
      expect(summary.averageBuildMs, 0);
      expect(summary.averageRasterMs, 0);
    });

    test('menghitung frame jank berdasarkan budget 16,67 ms', () {
      final smooth = buildTiming(buildUs: 5000, rasterUs: 3000);
      final janky = buildTiming(buildUs: 12000, rasterUs: 9000);

      final summary = PerformanceSummary.fromSamples([smooth, janky]);

      expect(summary.totalFrames, 2);
      expect(summary.jankyFrames, 1);
      expect(summary.jankPercent, 50);
      expect(summary.averageBuildMs, closeTo(8.5, 0.01));
      expect(summary.averageRasterMs, closeTo(6.0, 0.01));
      expect(summary.worstFrameMs, greaterThan(16.67));
    });

    test('p95 memakai sampel terurut dan worst adalah nilai terbesar', () {
      final samples = [
        for (var i = 0; i < 20; i++) buildTiming(buildUs: 2000, rasterUs: 2000),
        buildTiming(buildUs: 20000, rasterUs: 10000),
      ];

      final summary = PerformanceSummary.fromSamples(samples);

      expect(summary.totalFrames, 21);
      expect(summary.jankyFrames, 1);
      expect(summary.p95FrameMs, lessThan(summary.worstFrameMs));
      expect(summary.worstFrameMs, closeTo(31.1, 0.01));
    });
  });

  group('PerformanceMetrics recorder', () {
    test('hanya merekam sampel saat recording aktif', () {
      final metrics = PerformanceMetrics.instance;
      metrics.clear();

      metrics.startRecording();
      expect(metrics.isRecording, isTrue);
      metrics.recordTimings([
        buildTiming(buildUs: 5000, rasterUs: 3000),
        buildTiming(buildUs: 12000, rasterUs: 9000),
      ]);
      metrics.stopRecording();

      expect(metrics.isRecording, isFalse);
      expect(metrics.samples, hasLength(2));
      expect(metrics.summary.jankyFrames, 1);

      // Sampel setelah stop tidak boleh menambah hasil.
      metrics.recordTimings([buildTiming(buildUs: 1000, rasterUs: 1000)]);
      expect(metrics.samples, hasLength(2));

      metrics.clear();
      expect(metrics.samples, isEmpty);
    });

    test('startRecording membersihkan sampel lama', () {
      final metrics = PerformanceMetrics.instance;
      metrics.clear();
      metrics.startRecording();
      metrics.recordTimings([buildTiming(buildUs: 1000, rasterUs: 1000)]);
      metrics.stopRecording();
      expect(metrics.samples, hasLength(1));

      metrics.startRecording();
      expect(metrics.samples, isEmpty);
      metrics.stopRecording();
      metrics.clear();
    });
  });
}
