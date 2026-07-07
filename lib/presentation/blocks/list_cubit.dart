import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/data/models/response_models/base_model.dart';
import 'package:collection/collection.dart';

class ListResult<Model> {
  final List<Model> models;
  final int lastPage;

  ListResult({required this.models, required this.lastPage});
}

abstract class ListCubit<Query extends BaseQuery, Model extends BaseModel>
    extends BaseCubit {
  late Query query;
  List<Model> _models = [];

  ListCubit(BaseCubitState state) : super(state);

  Future<void> initial({required Query query}) async {
    emit(LoadingState());
    this.query = query;
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    debugPrint("$runtimeType: getModels from initial");
    final result = await getModels(page: 0);
    if (result != null) {
      addModels(data: result.models, page: 0, lastPage: result.lastPage);
    }
  }

  Future<void> search() async {
    emit(LoadingState());
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    debugPrint("$runtimeType: getModels from search");
    final result = await getModels(page: this.query.currentPage);
    if (result != null) {
      addModels(
          data: result.models,
          page: this.query.currentPage,
          lastPage: result.lastPage);
    }
  }

  Future<void> refresh() async {
    emit(RefreshState());
    debugPrint("$runtimeType: getModels from refresh");
    final result = await getModels(page: 0);
    if (result != null) {
      addModels(data: result.models, page: 0, lastPage: result.lastPage);
    }
  }

  Future<void> reload() async {
    emit(LoadingState());
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    debugPrint("$runtimeType: getModels from reload");
    final result = await getModels(page: 0);
    if (result != null) {
      addModels(data: result.models, page: 0, lastPage: result.lastPage);
    }
  }

  Future<void> loadMore() async {
    final int nextPage = query.currentPage + 1;
    if (nextPage <= query.lastPage) {
      emit(LoadingMoreState<Model>(models: List.from(_models)));
      debugPrint("$runtimeType: getModels from load More");
      final result = await getModels(page: nextPage);
      if (result != null) {
        addModels(
            data: result.models, page: nextPage, lastPage: result.lastPage);
      }
    }
  }

  Future<ListResult<Model>?> getModels({int page = 0});

  Future<void> addModels(
      {required List<Model> data,
      required int page,
      required int lastPage}) async {
    query.currentPage = page;
    query.lastPage = lastPage;

    if (page == 0) {
      _models.clear();
    }

    _models.addAll(data);
    //sortIfNeeded();
    updateList(_models);
  }

  Future<void> updateList(List<Model> newList) async {
    debugPrint('updateList cubit');
    emit(SuccessListState<Model>(models: List.from(newList)));
  }

  Future<void> updateModel(int index, Model newModel) async {}

  List<Model> get models {
    return _models;
  }

  remove({required Model model}) {
    try {
      _models.remove(model);
      updateList(_models);
    } catch (e) {
      catchError(e);
    }
  }

  removeAll() {
    _models.clear();
  }

  removeAt({required int index}) {
    try {
      _models.removeAt(index);
    } catch (e) {
      catchError(e);
    }
  }

  addAll({required List<Model> models}) {
    _models.addAll(models);
  }

  insert({required Model model, int? byIndex}) {
    debugPrint('insert');
    try {
      var index = indexBy(model: model);
      if (index != null && index != -1) {
        debugPrint('Модель найдена, её индекс: $index');
        _models.removeAt(index);
        _models.insert(index, model);
      } else {
        debugPrint('Модель не найдена, добавляем новую модель');
        _models.insert(byIndex ?? _models.length, model);
      }
      updateList(_models);
      debugPrint('updateList cubit');
    } catch (e) {
      catchError(e);
    }
  }

  // int get modelsLength {
  //   return _models.length;
  // }

  Model? modelById({required int id}) {
    return _models.firstWhereOrNull((element) {
      return element.baseId == id;
    });
  }

  Model? modelByIndex({required int index}) {
    try {
      return _models[index];
    } catch (e) {
      return null;
    }
  }

  int? indexBy({required Model model}) {
    int i = _models.indexWhere((element) => element.baseId == model.baseId);
    if (i == -1) {
      return null;
    }
    debugPrint('indexBy: $i');
    return i;
  }

  sortIfNeeded() {}

  sort(int Function(Model a, Model b) compare) {
    _models.sort(compare);
  }
}
