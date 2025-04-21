import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';
import 'package:collection/collection.dart';

abstract class ListCubit<Query extends BaseQuery, Model extends BaseModel>
    extends BaseCubit {
  late Query query;
  List<Model> _models = [];

  ListCubit(BaseCubitState state) : super(state);

  Future<void> initial({required Query query}) async {
    this._models = [];
    this.query = query;
    this.query.currentPage = 0;
    this.query.lastPage = 0;

    emit(LoadingState());
    await getModels(page: 0);
  }

  Future<void> search() async {
    emit(LoadingState());
    this._models = [];
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    await getModels(page: this.query.currentPage);
  }

  Future<void> refresh() async {
    this._models = [];
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    emit(RefreshState());
    await getModels(page: 0);
  }

  Future<void> reload() async {
    this._models = [];
    this.query.currentPage = 0;
    this.query.lastPage = 0;
    emit(LoadingState());
    await getModels(page: 0);
  }

  Future<void> loadMore() async {
    final int nextPage = query.currentPage + 1;
    if (nextPage > query.lastPage) {
      
      emit(SuccessListState<Model>(models: _models, date: DateTime.now()));
    } else {
      emit(LoadingMoreState());
      await getModels(page: nextPage);
    }
  }

  Future<void> getModels({
    int page = 0
    });

  Future<void> setResponse(
      {required List<Model> data,
      required int page,
      required int lastPage}) async {
    query.currentPage = page;
    query.lastPage = lastPage;
    addAll(models: data);

    sortIfNeeded();

    emit(SuccessListState<Model>(models: _models, date: DateTime.now()));
  }

  Future<void> update() async {
    emit(SuccessListState<Model>(models: _models, date: DateTime.now()));
  }

  List<Model> get models {
    return _models;
  }

  remove({required Model model}) {
    try {
      _models.remove(model);
    } catch (e) {
      catchError(e);
    }
  }

  removeAll() {
    _models = [];
  }

  removeAt({required int index}) {
    try {
      _models.removeAt(index);
    } catch (e) {
      catchError(e);
    }
  }

  addAll({required List<Model> models}) {
    models.forEach((element) {
      add(model: element);
      // _models?.add(element);
    });
    // _models?.addAll(models);
  }

  add({required Model model}) {
    try {
      var index = indexBy(model: model);
      if (index != null && index != -1) {
        _models.removeAt(index);
        _models.insert(index, model);
      } else {
        _models.add(model);
      }
    } catch (e) {
      catchError(e);
    }
  }

  insertToTop({required Model model}) {
    insert(model: model, byIndex: null);
  }

  insert({required Model model, required int? byIndex}) {
    try {
      var index = indexBy(model: model);
      if (index != null && index != -1) {
        _models.removeAt(index);
        _models.insert(index, model);
      } else {
        if (byIndex != null) {
          _models.insert(byIndex, model);
        } else {
          _models.insert(0, model);
        }
      }
    } catch (e) {
      catchError(e);
    }
  }

  int get modelsLanght {
    return _models.length;
  }

  Model? modelById({required int id}) {
    return _models.firstWhereOrNull((element) {
      if (element.baseId is String) {
        return int.parse(element.baseId) == id;
      } else {
        return element.baseId == id;
      }
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
    var i = _models.indexWhere((element) => (element.baseId is String)
        ? int.parse(element.baseId) == model.baseId
        : element.baseId == model.baseId);
    if (i == -1) {
      return null;
    }

    return i;
  }

  sortIfNeeded() {}

  sort(int Function(Model a, Model b) compare) {
    _models.sort(compare);
  }
}
