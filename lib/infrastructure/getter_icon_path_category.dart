import 'images.gen.dart';

String getIconPathCategoty(int id) {
  switch (id) {
    case 1:
      return IMG.icons.iconCategoryHotel;
    case 2:
      return IMG.icons.iconCategoryRooms;
    case 3:
      return IMG.icons.iconCategoryRestaurants;
    case 4:
      return IMG.icons.iconCategoryConferenceRooms;
    case 5:
      return IMG.icons.iconCategorySwimmingPools;
    case 6:
      return IMG.icons.iconCategorySeaBeach;
    case 7:
      return IMG.icons.iconCategorySportSpa;
    case 8:
      return IMG.icons.iconCategoryEntertainment;
    case 9:
      return IMG.icons.iconCategoryAnother;
    default:
      return IMG.icons.iconCategoryAnother;
  }
}
