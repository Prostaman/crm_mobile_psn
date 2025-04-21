import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/models/response_models/base_model.dart';

class CategoryModel extends BaseModel {
  final int id;
  final String description;
  //final String iconPath;

  CategoryModel({required this.id, required this.description});

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(id: map['id'],description:  map['description']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      return CategoryModel(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"]),
        description: json["name"].toString(),
      );
    } catch (e) {
      debugPrint(e.toString());
      throw e;
    }
  }
}
