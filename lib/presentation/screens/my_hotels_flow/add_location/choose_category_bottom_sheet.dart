import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/helpers/getter_icon_path_category.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/category_of_location_model.dart';

class CategoriesBottomSheet extends StatefulWidget {
  final Function(CategoryModel?) onTapCallback;
  final List<CategoryModel> categories;
  const CategoriesBottomSheet({Key? key, required this.onTapCallback, required this.categories}) : super(key: key);

  @override
  _CategoriesBottomSheetState createState() => _CategoriesBottomSheetState();
}

class _CategoriesBottomSheetState extends State<CategoriesBottomSheet> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 22, right: 22, bottom: 0, top: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Выберите категорию",
              style: textStyle(size: 22, weight: Semibold6),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: RawScrollbar(
                        thumbColor: const Color.fromARGB(255, 248, 166, 166),
                        radius: Radius.circular(8),
                        thumbVisibility: true,
                        child: ListView.builder(
                            itemCount: widget.categories.length,
                            itemBuilder: (context, index) {
                              return _buildItem(index);
                            })))),
            SizedBox(height: 16),
          ],
        ));
  }

  Widget _buildItem(int index) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 6.0), // Adds space between items
        child: GestureDetector(
            onTap: () {
              widget.onTapCallback(widget.categories[index]);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 23),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorBorderV2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(getIconPathCategoty(widget.categories[index].id), fit: BoxFit.scaleDown),
                  SizedBox(
                    width: 17,
                  ),
                  Expanded(
                      child: Text(
                    widget.categories[index].description,
                    style: textStyle(color: Colors.black, size: 18),
                  )),
                ],
              ),
            )));
  }
}
