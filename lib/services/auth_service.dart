import 'dart:io';

import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/api/api_container.dart';
import 'package:psn.hotels.hub/api/auth_api.dart';
import 'package:psn.hotels.hub/blocks/auth_user_cubit/auth_user_cubit.dart';
import 'package:psn.hotels.hub/blocks/flow_cubit/flow_cubit.dart';
import 'package:psn.hotels.hub/db/db_manager.dart';
import 'package:psn.hotels.hub/helpers/workmanager/workmanger_sync.dart';
import 'package:psn.hotels.hub/models/entities_database/my_hotel_model.dart';
import 'package:psn.hotels.hub/models/request_models/sign_in_request.dart';
import 'package:psn.hotels.hub/models/response_models/sign_in_response.dart';
import 'package:psn.hotels.hub/models/response_models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../repository/repository_container.dart';
import 'service_container.dart';

class AuthService {
  final String _onboardingKey = "onboarding_key";
  final String _authUserKey = "auth_user_key";
  final AuthApi _authApi = ApiContainer().authApi;

  final FlowCubit flowCubit = FlowCubit();

  final AuthUserCubit authUserCubit = AuthUserCubit();

  UserModel? get user {
    return authUserCubit.user;
  }

  Future<void> checkAutorization() async {
    UserModel? fetchedUser = await loadUserFromShared();
    await _changeFlowIfNeed(fetchedUser);
  }

  Future<void> loadData({required bool isEmptyHotels, required bool isEmptyCategories}) async {
    flowCubit.loading();
    debugPrint("Start loading from auth");

    bool isSyncedHotels = true;
    if (isEmptyHotels) {
      isSyncedHotels = await RepositoryContainer().hotelListRepository.downloadAllHotels();
    }

    bool isDownloadedCategories = true;
    if (isEmptyCategories) {
      isDownloadedCategories = await RepositoryContainer().categoriesRepository.downloadCategories();
    }

    if (isSyncedHotels && isDownloadedCategories) {
      flowCubit.home();
    }
    // await gelAllMyHotelsFromDBBackend();
  }

  // Future<void> gelAllMyHotelsFromDBBackend() async {
  //   var db = RepositoryContainer().locationsRepository.db;
  //   var locations =
  //       await RepositoryContainer().locationsRepository.getLocations();
  //   for (var locationModel in locations) {
  //     //добавление моих отелей
  //     var myHotel = await findMyHotelByHotelId(locationModel.hotelId, db);
  //     if (myHotel == null) {
  //       var hotel = await RepositoryContainer()
  //           .hotelListRepository
  //           .findHotelFromLocalDBById(locationModel.hotelId); // findHotelById
  //       if (hotel != null) {
  //         myHotel = await RepositoryContainer()
  //             .myHotelRepository
  //             .addMyHotel(hotel: hotel);
  //       }
  //     }
  //     // окончание добавления моих отелей
  //     //добавление локаций
  //     if (myHotel != null) {
  //       var location = (await db.findLocationsByCloudId(locationModel.cloudId)).firstOrNull;
  //       if (location == null) {
  //         locationModel.createdAt = DateTime.now().toIso8601String();
  //         locationModel.synced = true;
  //         db.insertLocation(locationModel);
  //       }
  //     }
  //     //окончание добавление локаций
  //   }
  // }

  Future<MyHotelModel?> findMyHotelByHotelId(int hotelId, DBManager db) async {
    var myHotelMap = await (await db.myHotelsDao()).findMyHotelById(hotelId);
    if (myHotelMap != null) {
      MyHotelModel myHotel = MyHotelModel.fromMap(myHotelMap);
      return myHotel;
    } else
      return null;
  }

  Future<UserModel> getUser() async {
    UserModel user = await loadUserFromShared();
    return user;
  }

  Future<UserModel?> login(SignInRequest model) async {
    try {
      model.key = ApiEnvironment.apiKey;
      SignInResponse? response = await _authApi.login(model);
      if (response != null) {
        if (response.success == true) {
          if (response.item != null) {
            if (response.item!.token != null) {
              response.item!.userName = model.login;
              //print("token: ${response.item!.token}");
              bool success = await _saveUserToShared(response.item);
              if (success == true) {
                //adding auto uploading files to the server, when app is closed
                initWorkManagerSyncing();

                return response.item;
              } else {
                throw ("Error saving user to shared");
              }
            }
          } else {
            ApiContainer().removeToken();
            throw ("Сервер не вернул токен. Пожалуйста попробуйте позже.");
          }
        } else {
          response.errors.forEach((errorMessage) {
            debugPrint("Error auth code: ${errorMessage.code}");
            debugPrint("Error auth message: ${errorMessage.message}");
          });

          throw (response);
        }
      } else {
        throw ("Empty response error");
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      bool success = await _removeUserFromShared();
      if (success == true) {
        await _changeFlowIfNeed(null);

        // if (cleadDB == true) {
        //   await RepositoryContainer().myHotelRepository.removeAll();
        //   await RepositoryContainer().locationsRepository.removeAll();
        // }

        // await Future.delayed(Duration(seconds: 1), () async {
        //   await _authApi.logout();
        // });
        ApiContainer().removeToken();
        Workmanager().cancelAll;
        return;
      } else {
        throw "Error removing user from shared";
      }
    } catch (e) {
      if (flowCubit.state == FlowState.Onboarding || flowCubit.state == FlowState.Login) {
        ApiContainer().removeToken();
      }
      throw e;
    }
  }

  _changeFlowIfNeed(UserModel? model) async {
    try {
      if (model != null) {
        if (model.token != null) {
          ApiContainer().setToken(model.token!);
          var onboarding = await _onboardingExist();
          if (onboarding == true) {
            bool tableOfHotelsIsEmpty = await (await DBManager().hotelsDao()).isTableHotelsEmpty();
            bool tableOfCategoriesIsEmpty = await (await DBManager().categoriesDao()).isTableCategoriesEmpty();
            if (tableOfHotelsIsEmpty || tableOfCategoriesIsEmpty) {
              await ServiceContainer().authService.loadData(isEmptyHotels: tableOfHotelsIsEmpty, isEmptyCategories: tableOfCategoriesIsEmpty);
            } else {
              if (Platform.isIOS) {
                await (await DBManager().filesDao()).updateUUID_of_Files();
              }
              var sinkService = ServiceContainer().sinkService;
              await sinkService.deleteRussianAndBelorusianHotels();
              sinkService.startDownloadHotels();
              sinkService.initObserverInternetConnection();
              flowCubit.home();
            }
          } else if (flowCubit.state != FlowState.Onboarding && onboarding == false) {
            flowCubit.onboarding();
          }
        } else {
          throw "Invalid token";
        }
      } else {
        flowCubit.login();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<bool> _onboardingExist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? json = prefs.getBool(_onboardingKey);
    if (json == null || json == false) {
      await prefs.setBool(_onboardingKey, true);

      return false;
    } else {
      return true;
    }
  }

  loadUserFromShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString(_authUserKey);
    if (json == null) {
      return null;
    }
    UserModel? userModel = JsonMapper.deserialize<UserModel>(json);
    authUserCubit.changeUser(userModel);
    return userModel;
  }

  _removeUserFromShared() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool success = await prefs.remove(_authUserKey);

    if (success == true) {
      authUserCubit.changeUser(null);
    }
    return success;
  }

  _saveUserToShared(UserModel? user) async {
    if (user != null) {
      if (user.token == null) {
        user.token = this.user?.token;
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String json = JsonMapper.serialize(user);

      bool success = await prefs.setString(_authUserKey, json);
      if (success == true) {
        authUserCubit.changeUser(user);
      }
      return success;
    }
  }
}
