import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class BaseApi {

  late Dio client;

  BaseApi();

  initClient(client) {
    this.client = client;
  }

  String buildQuery({required String url, required Map<String, String> query}) {
    if (query.keys.length > 0) {
      query.forEach((key, value) {
        if (url.contains("?") == false) {
          url += "?$key=$value";
        } else {
          url += "&$key=$value";
        }
      });
    }

    return url;
  }

  post(String url, final parameters) async {
    try {
      var response = await client.post(url, data: parameters);
      return response;
    } catch (e) {
      debugPrint("HTTP post $url\nError: $e\nparameters: $parameters");
      FirebaseCrashlytics.instance.log("HTTP post $url\nError: $e\nparameters: $parameters");
      throw e;
    }
  }

  get(String url) async {
    try {
      var response = await client.get(url);
      return response;
    } catch (e) {
      debugPrint("HTTP get $url\nError: $e");
      FirebaseCrashlytics.instance.log("HTTP get $url\nError: $e");
      throw e;
    }
  }

  put(String url, final parameters) async {
    try {
      var response = await client.put(url, data: parameters);
      return response;
    } catch (e) {
      debugPrint("HTTP put $url\nError: $e\nparameters: $parameters");
      FirebaseCrashlytics.instance.log("HTTP put $url\nError: $e\nparameters: $parameters");
      throw e;
    }
  }

  delete(String url, final parameters) async {
    try {
      var response = await client.delete(url, data: parameters);

      return response;
    } catch (e) {
       print("HTTP delete $url\nError: $e\nparameters: $parameters");
      FirebaseCrashlytics.instance.log("HTTP delete $url\nError: $e\nparameters: $parameters");
      throw e;
    }
  }

  sendFile(String url, FormData data) async {
    try {
      //client.options..headers["Content-Type"] = "multipart/form-data";
           // client.options..headers.remove("Content-Type");
      var response = await client.post(url, data: data);
      return response;
    } catch (e) {
      print("HTTP sendFile $url\nError: $e\ndata: $data");
      FirebaseCrashlytics.instance.log("HTTP sendFile $url\nError: $e\ndata: $data");
      //throw e;
    }
  }
}
