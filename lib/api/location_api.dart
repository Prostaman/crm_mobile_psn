import 'package:flutter/foundation.dart';
import 'package:psn.hotels.hub/api/base_api.dart';
import 'package:psn.hotels.hub/models/entities_database/location_model.dart';
import 'package:psn.hotels.hub/models/response_models/base_model_response.dart';
import 'package:psn.hotels.hub/models/response_models/locations_response.dart';

class LocationApi extends BaseApi {
  LocationApi() : super();

  Future<LocationsResponse?> getAll() async {
    try {
      var response = await super.get("getfacilities");
      var model = await compute(parseLocations, response.data);
      return model;
    } catch (e) {
      throw e;
    }
  }

  Future<LocationResponse> addLocation(
      {required LocationModel location}) async {
    try {
      var response = await super.post("addfacility", location.toJson);
      return LocationResponse.fromJson(response.data);
    } catch (e) {
      throw e;
    }
  }

  Future<BaseModelResponse?> deleteLocation(
      {required LocationModel request}) async {
    try {
      var response =
          await super.post("deletefacility", {"id": request.cloudId});
      return BaseModelResponse.fromJson(response.data);
    } catch (e) {
      //print("Error getting response deleteLocation: $e");
      throw e;
    }
  }
}



LocationsResponse parseLocations(dynamic responseBody) {
  return LocationsResponse.fromJson(responseBody);
}
