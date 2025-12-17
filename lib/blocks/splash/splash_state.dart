class SplashState {
  final bool error;
  final String message;
  final int progress;

  SplashState({this.error = false, this.message = '', this.progress = 0});

  SplashState copyWith({bool? error, String? message, int? progress}) {
    return SplashState(
      error: error ?? this.error,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}
