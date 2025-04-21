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
  final DateTime? date;
  final String? hash;
  SuccessListState({required this.models, this.date, this.hash});

  @override
  List<Object> get props => [models, date?.toString() ?? "", hash ?? ""];

  @override
  String toString() {
    return (date?.toString() ?? "") + (hash ?? "");
  }
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
    FirebaseCrashlytics.instance.recordFlutterError(FlutterErrorDetails(exception: textError));
    return textError;
  }
}
