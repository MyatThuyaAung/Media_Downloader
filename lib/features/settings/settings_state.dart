class SettingsState {
  final String? outputDirectory;
  final bool isLoading;
  final bool isSaving;

  const SettingsState({
    this.outputDirectory,
    this.isLoading = false,
    this.isSaving = false,
  });

  SettingsState copyWith({
    Object? outputDirectory = _undefined,
    bool? isLoading,
    bool? isSaving,
  }) {
    return SettingsState(
      outputDirectory: outputDirectory == _undefined
          ? this.outputDirectory
          : outputDirectory as String?,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class _Undefined {
  const _Undefined();
}

const _undefined = _Undefined();
