import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/api/auth_api.dart';
import 'package:psn.hotels.hub/api/category_of_location_api.dart';
import 'package:psn.hotels.hub/api/files_api.dart';
import 'package:psn.hotels.hub/api/hotel_api.dart';
import 'package:psn.hotels.hub/api/location_api.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

enum ApiState { local, dev, prod }

class ApiEnvironment {
  static String get apiKey {
    return "E9523213-6046-45DD-9360-A7FC825AA497";
  }

  static const ApiState apiState = ApiState.prod;

  static String _baseUrl() {
    switch (apiState) {
      case ApiState.local:
        return "";
      case ApiState.dev:
        return "";
      case ApiState.prod:
        return "https://api.poehalisnami.ua/crm/";
      default:
        return "";
    }
  }

  static String getApiURL() {
    switch (apiState) {
      case ApiState.local:
        return _baseUrl();
      case ApiState.dev:
        return _baseUrl();
      case ApiState.prod:
        return _baseUrl();
      default:
        return "";
    }
  }

  static int getMaxFileSize() {
    switch (apiState) {
      case ApiState.local:
        return 2097152;
      case ApiState.dev:
        return 2097152;
      case ApiState.prod:
        return 26214400;
      default:
        return 26214400;
    }
  }

  static String getMaxFileSizeText() {
    switch (apiState) {
      case ApiState.local:
        return "2MB";
      case ApiState.dev:
        return "2MB";
      case ApiState.prod:
        return "25MB";
      default:
        return "25MB";
    }
  }
}

class ApiContainer {
  static final ApiContainer _singleton = ApiContainer._initialize();

  factory ApiContainer() {
    return _singleton;
  }

  final Dio client = Dio(BaseOptions(
    baseUrl: ApiEnvironment.getApiURL(),
    connectTimeout: Duration(milliseconds: 60000),
    receiveTimeout: Duration(milliseconds: 60000),
  ));

  final authApi = AuthApi();
  final filesApi = FilesApi();
  final hotelApi = HotelApi();
  final locationApi = LocationApi();
  final categoryApi = CategoryApi();

  ApiContainer._initialize() {
    client.options
      ..headers["content-type"] = "application/json"
      ..headers["Accept"] = "application/json";

    client.interceptors.add(
      PrettyDioLogger(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseBody: false,
        responseHeader: false,
        error: true,
        compact: false,
      ),
    );

    authApi.initClient(client);
    filesApi.initClient(client);
    hotelApi.initClient(client);
    locationApi.initClient(client);
    categoryApi.initClient(client);
  }

  setToken(String token) {
    client.options..headers["Authorization"] = "Bearer $token";
    debugPrint("Bearer $token");
  }

  removeToken() {
    client.options..headers.remove("Authorization");
  }
}
