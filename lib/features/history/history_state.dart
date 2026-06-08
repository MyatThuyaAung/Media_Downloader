import '../../models/download_task.dart';

class HistoryState {
  final List<DownloadTask> entries;
  final bool isLoading;

  const HistoryState({this.entries = const [], this.isLoading = false});

  HistoryState copyWith({
    List<DownloadTask>? entries,
    bool? isLoading,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
