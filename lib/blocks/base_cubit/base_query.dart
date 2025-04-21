part of 'base_cubit.dart';

class BaseQuery {
  int lastPage = 1;
  int currentPage = 1;

  String search = "";

  BaseQuery({String? search}) {
    this.search = search ?? "";
  }

  Map<String, String> get serialize {
    Map<String, String> _query = {};
    if (search.length > 0) {
      _query["search"] = search;
    } else {
      _query.remove("search");
    }
    return _query;
  }

  bool get searching {
    if (search.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }
}
