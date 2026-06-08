import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/history_service.dart';
import '../../models/download_task.dart';
import 'history_state.dart';

final _historyService = HistoryService();

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>(
  (ref) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final entries = await _historyService.load();
    state = HistoryState(entries: entries, isLoading: false);
  }

  Future<void> addEntry(DownloadTask task) async {
    final entry = task.copyWith(
      status: DownloadTaskStatus.done,
      progress: null,
    );
    state = state.copyWith(entries: [entry, ...state.entries]);
    await _historyService.save(state.entries);
  }

  Future<void> removeEntry(String taskId) async {
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != taskId).toList(),
    );
    await _historyService.save(state.entries);
  }

  Future<void> clearHistory() async {
    state = const HistoryState(entries: []);
    await _historyService.save([]);
  }
}
