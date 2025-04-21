import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';
import 'package:collection/collection.dart';

abstract class MiltiPickerCubitProtocol<Model extends BaseModel> {
  late List<Model> selected;
}

mixin MultiPickerCubitMixit<Model extends BaseModel> implements MiltiPickerCubitProtocol<Model> {
  ListCubit get cubit;

  bool isSelected(Model model) {
    var item = selected.firstWhereOrNull((element) => element.baseId == model.baseId);
    return item != null;
  }

  Future<void> select(Model model) async {
    var index = selected.indexWhere((element) => element.baseId == model.baseId);
    if (index != -1) {
      selected.removeAt(index);
    } else {
      selected.add(model);
    }
    cubit.update();
  }
}
