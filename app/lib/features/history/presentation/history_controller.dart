import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phishguard/core/providers.dart';
import 'package:phishguard/features/history/data/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(sharedPreferencesProvider)),
);

/// The saved checks, newest first. Every screen that shows history watches this.
final historyProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryEntry>>(HistoryController.new);

class HistoryController extends AsyncNotifier<List<HistoryEntry>> {
  HistoryRepository get _repo => ref.read(historyRepositoryProvider);

  @override
  Future<List<HistoryEntry>> build() async => ref.watch(historyRepositoryProvider).all();

  Future<void> add(HistoryEntry entry) async {
    await _repo.save(entry);
    state = AsyncData(_repo.all());
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const AsyncData([]);
  }
}
