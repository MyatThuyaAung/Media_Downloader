import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/settings_service.dart';
import 'settings_state.dart';

final _settingsService = SettingsService();

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await load();
  }

  Future<void> load() async {
    final outputDirectory = await _settingsService.getOutputDirectory();

    state = SettingsState(
      outputDirectory: outputDirectory,
      isLoading: false,
    );
  }

  Future<void> setOutputDirectory(String? path) async {
    state = state.copyWith(isSaving: true);
    await _settingsService.setOutputDirectory(path);
    state = state.copyWith(outputDirectory: path, isSaving: false);
  }
}
