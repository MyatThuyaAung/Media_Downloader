class SettingsState {
  final String? outputDirectory;
  final String? defaultCookiesBrowser;
  final bool isLoading;
  final bool isSaving;

  const SettingsState({
    this.outputDirectory,
    this.defaultCookiesBrowser,
    this.isLoading = false,
    this.isSaving = false,
  });

  SettingsState copyWith({
    String? outputDirectory,
    String? defaultCookiesBrowser,
    bool? isLoading,
    bool? isSaving,
    Object? outputDirectorySentinel = _undefined,
    Object? defaultCookiesBrowserSentinel = _undefined,
  }) {
    return SettingsState(
      outputDirectory: outputDirectorySentinel == _undefined
          ? this.outputDirectory
          : outputDirectory,
      defaultCookiesBrowser: defaultCookiesBrowserSentinel == _undefined
          ? this.defaultCookiesBrowser
          : defaultCookiesBrowser,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();
