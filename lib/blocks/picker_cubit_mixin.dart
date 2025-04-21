import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

abstract class PickerCubitProtocol<Model extends BaseModel> {
  late Model selected;
}

mixin PickerCubitMixit<Model extends BaseModel> implements PickerCubitProtocol<Model> {
  ListCubit get cubit;

  bool isSelected(Model model) {
    return selected.baseId == model.baseId;
  }

  Future<void> select(Model model) async {
    selected = model;
    cubit.update();
  }
}
