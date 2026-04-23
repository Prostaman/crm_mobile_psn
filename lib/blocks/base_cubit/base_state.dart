part of 'base_cubit.dart';

abstract class BaseCubitState extends Equatable {
  const BaseCubitState();

  @override
  List<Object?> get props => [];
}

class InitialState extends BaseCubitState {}

class LoadingState extends BaseCubitState {}

class LoadingMoreState extends BaseCubitState {}

class RefreshState extends BaseCubitState {}

class SuccessModelState<Model> extends BaseCubitState {
  final Model model;
  final DateTime? date;
  final String? hash;
  SuccessModelState({required this.model, this.date, this.hash});

  @override
  List<Object?> get props => [model, date?.toString() ?? "", hash ?? ""];
}

class SuccessListState<Model> extends BaseCubitState {
  final List<Model> models;
  SuccessListState({required this.models});

  @override
  List<Object?> get props => [models];
}

class ErrorState extends BaseCubitState {
  final String? error;

  const ErrorState({this.error});

  @override
  List<Object> get props => [error.toString()];

  @override
  String toString() {
    String textError = error.toString();
    debugPrint(error);
    FirebaseCrashlytics.instance.log("Error state:$textError");
    FirebaseCrashlytics.instance
        .recordFlutterError(FlutterErrorDetails(exception: textError));
    return textError;
  }
}
