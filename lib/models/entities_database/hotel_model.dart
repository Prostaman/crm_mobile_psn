import 'package:psn.hotels.hub/models/response_models/base_model.dart';

class HotelModel extends BaseModel {
  HotelModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.long,
    required this.active,
    required this.cid,
    required this.country,
    required this.resort,
  });

  int id;
  String name;
  double lat;
  double long;
  bool active;
  String cid;
  String country;
  String resort;
  dynamic get baseId {
    return id;
  }

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    try {
      return HotelModel(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"]),
        name: json["name"].toString(),
        lat: json["lat"].toDouble(),
        long: json["long"].toDouble(),
        active: json["active"],
        cid: json["cid"] is String ? json["cid"] : json["cid"].toString(),
        country: json["country"].toString(),
        resort: json["resort"].toString(),
      );
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'long': long,
      'active': active ? 1 : 0, // Convert boolean to integer
      'cid': cid,
      'country': country,
      'resort': resort
    };
  }

   // Manually define fromMap method
  factory HotelModel.fromMap(Map<String, dynamic> map) {
    return HotelModel(
      id: map['id'],
      name: map['name'],
      lat: map['lat'],
      long: map['long'],
      active: map['active'] == 1, // Convert integer to boolean
      cid: map['cid'],
      country: map['country'],
      resort: map['resort']
    );
  }
  
}
