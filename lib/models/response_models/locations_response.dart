import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'dart:convert';

LocationsResponse hotelsResponseFromJson(String str) => LocationsResponse.fromJson(json.decode(str));

class LocationsResponse extends BaseModelResponse {
  LocationsResponse({
    required this.list,
    required bool success,
  }) {
    super.success = success;
    super.errors = errors;
  }

  List<LocationModel>? list;

  factory LocationsResponse.fromJson(Map<String, dynamic> json) {
    return LocationsResponse(
      list: json["list"] != null
          ? List<LocationModel>.from(json["list"].map((x) => LocationModel.fromJson(x)))
          : [],
      success: json["success"],
    );
  }
}

class LocationResponse extends BaseModelResponse {
  LocationResponse({
    required this.item,
    required bool success,
  }) {
    super.success = success;
  }

  LocationModel? item;

  factory LocationResponse.fromJson(Map<String, dynamic> json) {
    return LocationResponse(
      item: json["item"] != null ? LocationModel.fromJson(json["item"]) : null,
      success: json["success"],
    );
  }
}
