import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

abstract class LocalSearchCubitProtocol<Model extends BaseModel> {
  List<Model> saved = [];
}

mixin LocalSearchCubitMixin<Model extends BaseModel>
    implements LocalSearchCubitProtocol<Model> {
  ListCubit get cubit;

  Future<void> localSearch() async {
    debugPrint("cubit.models ${cubit.models}");
    if (cubit.query.is_searching == true) {
      print("search");
      cubit.search();
    } else {
      debugPrint("add all models: ${saved.cast<Model>()}");
      cubit.addAll(models: saved.cast<Model>()); // Cast to List<Model>
    }
    cubit.updateList();
  }
}
