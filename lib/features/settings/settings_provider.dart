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
    final defaultSubtitleLang = await _settingsService.getDefaultSubtitleLang();
    final defaultCookiesBrowser =
        await _settingsService.getDefaultCookiesBrowser();

    state = SettingsState(
      outputDirectory: outputDirectory,
      defaultSubtitleLang: defaultSubtitleLang,
      defaultCookiesBrowser: defaultCookiesBrowser,
      isLoading: false,
    );
  }

  Future<void> setOutputDirectory(String? path) async {
    state = state.copyWith(isSaving: true);
    await _settingsService.setOutputDirectory(path);
    state = state.copyWith(outputDirectory: path, isSaving: false);
  }

  Future<void> setDefaultSubtitleLang(String? value) async {
    state = state.copyWith(isSaving: true);
    await _settingsService.setDefaultSubtitleLang(value);
    state = state.copyWith(defaultSubtitleLang: value, isSaving: false);
  }

  Future<void> setDefaultCookiesBrowser(String? value) async {
    state = state.copyWith(isSaving: true);
    await _settingsService.setDefaultCookiesBrowser(value);
    state = state.copyWith(defaultCookiesBrowser: value, isSaving: false);
  }
}
