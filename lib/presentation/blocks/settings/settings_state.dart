import '../base_cubit/base_cubit.dart';

class SettingsState extends BaseCubitState {
  final bool wifiEnabled;
  final int qualityIndex;

  const SettingsState({
    required this.wifiEnabled,
    required this.qualityIndex,
  });

  SettingsState copyWith({
    bool? wifiEnabled,
    int? qualityIndex,
    bool? isLoading,
    bool? wasDeleting,
  }) {
    return SettingsState(
      wifiEnabled: wifiEnabled ?? this.wifiEnabled,
      qualityIndex: qualityIndex ?? this.qualityIndex,
    );
  }

  @override
  List<Object?> get props => [wifiEnabled, qualityIndex];
}
