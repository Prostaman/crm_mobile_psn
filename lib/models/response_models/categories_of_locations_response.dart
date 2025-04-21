import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';

//CategoriesResponse categoriesResponseFromJson(String str) => CategoriesResponse.fromJson(json.decode(str));

class CategoriesResponse extends BaseModelResponse {
  CategoriesResponse({
    required this.list,
    required bool success,
  }) {
    super.success = success;
    super.errors = errors;
  }

  List<CategoryModel>? list;

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    return CategoriesResponse(
      list: json["list"] != null
          ? List<CategoryModel>.from(json["list"].map((x) => CategoryModel.fromJson(x)))
          : <CategoryModel>[],
      success: json["success"],
    );
  }
}

