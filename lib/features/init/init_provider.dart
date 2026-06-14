import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/binary_manager.dart';

enum InitStatus { loading, done, error }

class InitState {
  final InitStatus status;
  final String step;
  final String? error;

  const InitState({
    this.status = InitStatus.loading,
    this.step = 'Initializing...',
    this.error,
  });

  InitState copyWith({InitStatus? status, String? step, String? error}) {
    return InitState(
      status: status ?? this.status,
      step: step ?? this.step,
      error: error,
    );
  }
}

class InitNotifier extends Notifier<InitState> {
  @override
  InitState build() => const InitState();

  Future<void> initialize() async {
    try {
      state = state.copyWith(step: 'Setting up yt-dlp...');
      await BinaryManager.instance.ytDlpPath;

      state = state.copyWith(step: 'Setting up FFmpeg...');
      await BinaryManager.instance.ffmpegPath;

      state = state.copyWith(step: 'Setting up JavaScript runtime (Deno)...');
      await BinaryManager.instance.denoPath;

      state = const InitState(status: InitStatus.done, step: 'Ready');
    } catch (e) {
      state = InitState(
        status: InitStatus.error,
        step: 'Initialization failed',
        error: e.toString(),
      );
    }
  }
}

final initProvider = NotifierProvider<InitNotifier, InitState>(
  InitNotifier.new,
);
