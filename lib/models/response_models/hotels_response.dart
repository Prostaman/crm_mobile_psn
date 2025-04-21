import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'dart:convert';

HotelsResponse hotelsResponseFromJson(String str) => HotelsResponse.fromJson(json.decode(str));

class HotelsResponse extends BaseModelResponse {
  HotelsResponse({
    required this.list,
    required bool success,
  }) {
    super.success = success;
    super.errors = errors;
  }

  List<HotelModel>? list;

  factory HotelsResponse.fromJson(Map<String, dynamic> json) {
    return HotelsResponse(
      list: json["list"] != null
          ? List<HotelModel>.from(json["list"].map((x) => HotelModel.fromJson(x)))
          : <HotelModel>[],
      success: json["success"],
    );
  }
}

