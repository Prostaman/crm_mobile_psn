import 'package:dart_json_mapper/dart_json_mapper.dart';


@jsonSerializable
class BaseModel {
  dynamic get baseId {
    return null;
  }

  @JsonProperty(ignore: true)
  @override
  String toString() {
    return this.runtimeType.toString() + "{ id: $baseId,}";
  }
}
