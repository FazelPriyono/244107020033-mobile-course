import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_task_rounded, color: Color(0xFF0F766E), size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tambah Catatan Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data akan divalidasi oleh Domain UseCase sebelum disimpan ke SQLite:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Misal: Review Bab 7 Clean Architecture',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tuliskan catatan atau tugas penting...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Simpan via UseCase'),
            onPressed: () async {
              final title = titleController.text;
              final body = bodyController.text;

              final addNoteUseCase = ref.read(addNoteProvider);
              final result = await addNoteUseCase(title: title, body: body);

              if (ctx.mounted) {
                Navigator.pop(ctx);
              }

              if (result.failure != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text(result.failure!.message)),
                        ],
                      ),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              } else {
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Catatan tervalidasi & tersimpan via Clean Architecture.'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF0F766E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(int id) async {
    final deleteUseCase = ref.read(deleteNoteProvider);
    final result = await deleteUseCase(id);

    if (result.failure != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.failure!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Catatan berhasil dihapus dari database lokal.'),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clean Architecture Notes'),
            Text(
              'Week 7 • Feature-First • SOLID Compliant',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan & Tema',
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.folder_special_rounded, size: 20),
              text: 'Catatan (${notesAsync.value?.length ?? 0})',
            ),
            const Tab(
              icon: Icon(Icons.hub_outlined, size: 20),
              text: 'Arsitektur & SOLID',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ==================== TAB 1: DAFTAR CATATAN ====================
          Column(
            children: [
              // Header Card Status Clean Architecture
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF0F766E), const Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withAlpha(isDark ? 30 : 60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: Colors.amberAccent),
                              SizedBox(width: 6),
                              Text(
                                'CLEAN ARCHITECTURE ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        dirtyAsync.when(
                          data: (count) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: count > 0 ? Colors.amber.shade400 : Colors.teal.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count lokal (dirty)',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Presentation  →  Domain (UseCases)  ←  Data (SQLite)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dependency Rule aktif: Domain steril dari framework, UI steril dari SQL.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar untuk memfilter catatan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari catatan berdasarkan judul atau isi...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withAlpha(30) : Colors.grey.shade300,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Daftar Catatan Reaktif
              Expanded(
                child: notesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 12),
                          Text('Gagal memuat catatan: $e', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                            ),
                            onPressed: () => ref.invalidate(notesProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (notes) {
                    final filteredNotes = _searchQuery.isEmpty
                        ? notes
                        : notes
                            .where((n) =>
                                n.title.toLowerCase().contains(_searchQuery) ||
                                n.body.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filteredNotes.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withAlpha(isDark ? 40 : 20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.note_alt_outlined,
                                  size: 48,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Belum ada catatan bisnis.'
                                    : 'Tidak ada catatan yang cocok dengan pencarian.',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Tekan tombol "Tambah Catatan" untuk membuat entity baru.'
                                    : 'Coba kata kunci pencarian yang lain.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _showAddNoteDialog,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Buat Catatan Pertama'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFF0F766E),
                      onRefresh: () async {
                        ref.invalidate(notesProvider);
                        ref.invalidate(dirtyCountProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return NoteTile(
                            note: note,
                            onTap: () => context.push('/note/${note.id}'),
                            onDelete: () {
                              if (note.id != null) {
                                _handleDelete(note.id!);
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ==================== TAB 2: ARSITEKTUR & SOLID ====================
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Alur 3 Layer
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.layers_rounded, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Text(
                              'Visualisasi 3 Layer Clean Architecture',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLayerBox(
                          title: '1. Presentation Layer (UI & State)',
                          subtitle: 'NotesPage, NoteDetailPage, SettingsPage, Riverpod Providers',
                          color: Colors.blue.shade700,
                          bg: Colors.blue.shade50,
                          detail:
                              'Membaca state melalui UseCase/Notifier. Steril dari SQL, Dio, maupun JSON decoding.',
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.grey),
                          ),
                        ),
                        _buildLayerBox(
                          title: '2. Domain Layer (The Core / Business Logic)',
                          subtitle: 'Entity Note, Kontrak NoteRepository, UseCases (GetNotes, AddNote)',
                          color: const Color(0xFF0F766E),
                          bg: const Color(0xFF0F766E).withAlpha(25),
                          detail:
                              'Pure Dart tanpa framework Flutter/package luar. Semua aturan validasi bisnis tinggal di sini.',
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.grey),
                          ),
                        ),
                        _buildLayerBox(
                          title: '3. Data Layer (Infrastructure & Persistence)',
                          subtitle: 'NoteModel (toMap/fromMap), NoteRepositoryImpl, SQLite DB',
                          color: Colors.orange.shade800,
                          bg: Colors.orange.shade50,
                          detail:
                              'Mengimplementasikan kontrak domain. Menghubungkan entity dengan tabel SQLite offline.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card Perbedaan Entity vs Model
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.compare_arrows_rounded, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Perbedaan Entity vs Model',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Table(
                          border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          children: const [
                            TableRow(
                              decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Kriteria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Domain Entity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Data Model', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Lokasi', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('domain/entities', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('data/models', style: TextStyle(fontSize: 11))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Serialisasi', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Bebas toMap/fromMap', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('toMap, fromMap, toEntity', style: TextStyle(fontSize: 11))),
                              ],
                            ),
                            TableRow(
                              children: [
                                Padding(padding: EdgeInsets.all(8), child: Text('Peran', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Objek aturan bisnis', style: TextStyle(fontSize: 11))),
                                Padding(padding: EdgeInsets.all(8), child: Text('Representasi data storage', style: TextStyle(fontSize: 11))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card 5 Prinsip SOLID
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Text(
                              'Penerapan 5 Prinsip SOLID',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSolidItem('S', 'Single Responsibility', 'Setiap kelas hanya punya satu alasan berubah: AddNote hanya memvalidasi & menambah, NoteModel hanya serialisasi.'),
                        _buildSolidItem('O', 'Open/Closed', 'Fitur baru dapat ditambahkan via UseCase baru tanpa mengubah repository interface yang telah berjalan.'),
                        _buildSolidItem('L', 'Liskov Substitution', 'FakeNoteRepository dapat disuntikkan menggantikan NoteRepositoryImpl tanpa merusak logika klien.'),
                        _buildSolidItem('I', 'Interface Segregation', 'Kontrak dipisahkan per domain (NoteRepository terpisah dari SettingsRepository).'),
                        _buildSolidItem('D', 'Dependency Inversion', 'Presentation dan UseCase bergantung pada abstraksi interface NoteRepository, bukan kelas konkret NoteRepositoryImpl.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Catatan'),
      ),
    );
  }

  Widget _buildLayerBox({
    required String title,
    required String subtitle,
    required Color color,
    required Color bg,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSolidItem(String letter, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
