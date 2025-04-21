import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:psn.hotels.hub/blocks/hotels/hotels_dialog_cubit.dart';
import 'package:psn.hotels.hub/helpers/images.gen.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/models/entities_database/hotel_model.dart';
import 'package:psn.hotels.hub/ui/buttons/default_button.dart';
import 'package:psn.hotels.hub/ui/items/search_field_box.dart';

class HotelsBottomSheet extends StatefulWidget {
  final Function(HotelModel?) onTapCallback;
  const HotelsBottomSheet({Key? key, required this.onTapCallback}) : super(key: key);

  @override
  _HotelsBottomSheetState createState() => _HotelsBottomSheetState();
}

class _HotelsBottomSheetState extends State<HotelsBottomSheet> {
  HotelModel? _selectedModel;

  HotelsDialogCubit get _hotelDialogCubit {
    return BlocProvider.of<HotelsDialogCubit>(context);
  }

  bool isLoading = false;
  Future<void>? futureGetNearestHotels;

  @override
  void initState() {
    super.initState();
    //_hotelDialogCubit.query.search = "";
    futureGetNearestHotels = getGetNearestHotels();
  }

  Future<void> getGetNearestHotels() async {
    await _hotelDialogCubit.removeAll();
    var nearestHotels = await _hotelDialogCubit.getNearestHotels();
    debugPrint("nearestHotels:${nearestHotels.length}");
    _hotelDialogCubit.models.addAll(nearestHotels);
    //await _hotelDialogCubit.refresh();
  }

  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left:22, right: 22, bottom: MediaQuery.of(context).viewInsets.bottom+22,top: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Выберите отель",
              style: textStyle(size: 22, weight: Semibold6),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 22),
            SearchFieldBox(
              placeholder: "Поиск отеля",
              callback: (newValue) async {
                setState(() {
                  _hotelDialogCubit.query.search = newValue;
                  isLoading = true;
                });
                await _hotelDialogCubit.search();
                setState(() {
                  isLoading = false;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: FutureBuilder(
                      future: futureGetNearestHotels,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error occurred: ${snapshot.error}"));
                        } else {
                          // print(
                          //     "length of search hotels in view:${_hotelDialogCubit.models}");
                          return isLoading
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _hotelDialogCubit.models.isEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          IMG.icons.hotelListEmptyPNG,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.scaleDown
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Отели не найдены",
                                          style: textStyle(size: 16),
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    )
                                  : Scrollbar(
                                      child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Color.fromRGBO(234, 234, 234, 1), // Set the color of the border
                                              width: 1.0, // Set the width of the border
                                            ),
                                            borderRadius: BorderRadius.circular(10.0), // Set the border radius
                                          ),
                                          child: ListView.builder(
                                            itemCount: _hotelDialogCubit.models.length,
                                            itemBuilder: (context, index) {
                                              return Column(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedModel = _hotelDialogCubit.models[index];
                                                      });
                                                    },
                                                    child: _hotelDialogCubit.models[index] == _selectedModel
                                                        ? Container(
                                                            margin: EdgeInsets.symmetric(vertical: 4),
                                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Color.fromRGBO(242, 99, 39, 0.08),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                    child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      "${_hotelDialogCubit.models[index].name}",
                                                                      style: textStyle(size: 18, weight: FontWeight.bold, color: ColorOrange),
                                                                    ),
                                                                    Text(
                                                                      "${_hotelDialogCubit.models[index].country}, ${_hotelDialogCubit.models[index].resort}",
                                                                      style: textStyle(color: ColorOrange),
                                                                    )
                                                                  ],
                                                                )),
                                                              ],
                                                            ),
                                                          )
                                                        : Container(
                                                            margin: EdgeInsets.symmetric(vertical: 4),
                                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                    child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      "${_hotelDialogCubit.models[index].name}",
                                                                      style: textStyle(size: 18),
                                                                    ),
                                                                    Text(
                                                                      "${_hotelDialogCubit.models[index].country}, ${_hotelDialogCubit.models[index].resort}",
                                                                      style: textStyle(color: Color.fromRGBO(160, 160, 160, 1)),
                                                                    )
                                                                  ],
                                                                )),
                                                              ],
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              );
                                            },
                                          )));
                        }
                      })),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DefaultButton(
                    textSize: 18,
                    title: "Отмена",
                    scheme: DefaultButtonScheme.White,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DefaultButton(
                    title: "Выбрать",
                    textSize: 18,
                    enable: _selectedModel != null,
                    scheme: DefaultButtonScheme.Orange,
                    onPressed: () {
                      widget.onTapCallback(_selectedModel);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            )
          ],
        ));
  }
}
