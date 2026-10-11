import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/token_store.dart';

// ---------------------------------------------------------------------------
// Providers infrastruktur
// ---------------------------------------------------------------------------

/// Provider untuk [TokenStore] — satu instance di seluruh app.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Provider untuk [AuthRepository] — siap diganti implementasi Firebase.
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

// ---------------------------------------------------------------------------
// Provider state autentikasi
// ---------------------------------------------------------------------------

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      await ref
          .read(tokenStoreProvider)
          .save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
