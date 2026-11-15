import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance_metrics.dart';
import '../../../notes/domain/entities/note.dart';
import '../../../notes/presentation/widgets/note_tile.dart';

/// Halaman alat ukur performa (dev tool) untuk praktikum Week 11.
///
/// Benchmark ini membangun daftar Panjang menggunakan [NoteTile] yang sama
/// dengan layar catatan, lalu melakukan scroll cepat (lazy loading) selama
/// beberapa detik sambil merekam [FrameTiming] secara global.
class PerformanceBenchmarkPage extends ConsumerStatefulWidget {
  const PerformanceBenchmarkPage({super.key});

  @override
  ConsumerState<PerformanceBenchmarkPage> createState() =>
      _PerformanceBenchmarkPageState();
}

enum _BenchmarkPhase { idle, running, done }

class _PerformanceBenchmarkPageState
    extends ConsumerState<PerformanceBenchmarkPage> {
  static const int _itemCount = 300;
  static const Duration _runDuration = Duration(seconds: 5);

  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  _BenchmarkPhase _phase = _BenchmarkPhase.idle;
  PerformanceSummary? _summary;
  List<Note> _notes = const <Note>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startBenchmark();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<Note> _generateNotes() {
    final now = DateTime.now();
    return List<Note>.generate(
      _itemCount,
      (index) => Note(
        id: index + 1,
        title: 'Catatan Benchmark #${index + 1}',
        body:
            'Isi catatan uji performa untuk mengukur biaya build, layout, dan '
            'paint NoteTile di dalam ListView.builder.',
        updatedAt: now.subtract(Duration(minutes: index)),
        dirty: index % 3 == 0,
      ),
    );
  }

  Future<void> _startBenchmark() async {
    if (_phase == _BenchmarkPhase.running) return;

    setState(() {
      _phase = _BenchmarkPhase.running;
      _summary = null;
      _notes = _generateNotes();
    });

    // Pastikan daftar sudah dibangun sebelum scroll dimulai.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    PerformanceMetrics.instance.startRecording();

    var forward = true;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (forward) {
        final target = position.pixels + 600;
        if (target >= position.maxScrollExtent - 20) {
          forward = false;
          _scrollController.jumpTo(position.maxScrollExtent);
        } else {
          _scrollController.jumpTo(target);
        }
      } else {
        final target = position.pixels - 600;
        if (target <= 20) {
          forward = true;
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(target);
        }
      }
    });

    await Future<void>.delayed(_runDuration);
    if (!mounted) return;

    _timer?.cancel();
    _timer = null;
    PerformanceMetrics.instance.stopRecording();

    setState(() {
      _summary = PerformanceMetrics.instance.summary;
      _phase = _BenchmarkPhase.done;
    });
  }

  void _reset() {
    _timer?.cancel();
    _timer = null;
    PerformanceMetrics.instance.clear();
    setState(() {
      _phase = _BenchmarkPhase.idle;
      _summary = null;
      _notes = const <Note>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageCache = PaintingBinding.instance.imageCache;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark Performa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Benchmark',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Lazy loading + scroll cepat (ListView.builder + NoteTile)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_itemCount item • ${_runDuration.inSeconds} detik • '
                  'budget frame 16,67 ms (60 FPS)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                        onPressed: _phase == _BenchmarkPhase.running
                            ? null
                            : _startBenchmark,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          _phase == _BenchmarkPhase.running
                              ? 'Benchmark berjalan...'
                              : 'Jalankan Benchmark',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(summary: _summary, phase: _phase),
                const SizedBox(height: 8),
                Text(
                  'Image cache: ${imageCache.currentSize} entri / '
                  '${(imageCache.currentSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB '
                  '(maks ${imageCache.maximumSize} entri / '
                  '${(imageCache.maximumSizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Text(
                      'Tekan "Jalankan Benchmark" untuk memulai pengukuran.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return NoteTile(
                        note: note,
                        onTap: () {},
                        onDelete: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.phase});

  final PerformanceSummary? summary;
  final _BenchmarkPhase phase;

  @override
  Widget build(BuildContext context) {
    if (phase == _BenchmarkPhase.idle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Belum ada pengukuran. Metrik frame akan muncul di sini.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    final data = summary;
    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Mengukur frame...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F766E).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xFF0F766E),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hasil Profiling Frame',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Total Frame', value: '${data.totalFrames}'),
              _MetricChip(
                label: 'Jank (>16,67 ms)',
                value: '${data.jankyFrames}',
                highlight: data.jankyFrames > 0,
              ),
              _MetricChip(
                label: 'Jank',
                value: '${data.jankPercent.toStringAsFixed(1)}%',
                highlight: data.jankPercent > 5,
              ),
              _MetricChip(
                label: 'Rata-rata',
                value: '${data.averageFrameMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'P95',
                value: '${data.p95FrameMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'Worst',
                value: '${data.worstFrameMs.toStringAsFixed(2)} ms',
                highlight: data.worstFrameMs > 16.67,
              ),
              _MetricChip(
                label: 'Build Rata-rata',
                value: '${data.averageBuildMs.toStringAsFixed(2)} ms',
              ),
              _MetricChip(
                label: 'Raster Rata-rata',
                value: '${data.averageRasterMs.toStringAsFixed(2)} ms',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Colors.red.shade700 : const Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
