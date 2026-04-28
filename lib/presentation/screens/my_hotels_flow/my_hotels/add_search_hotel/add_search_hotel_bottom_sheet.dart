import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/my_hotels/hotels_search/hotels_dialog_cubit.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';
import 'package:psn.hotels.hub/presentation/buttons/default_button.dart';
import 'package:psn.hotels.hub/presentation/items/search_field_box.dart';

import '../../../../../blocks/my_hotels/hotels_search/hotel_search_state.dart';
import '../../../../items/pagination_list_view.dart';

class AddSearchHotelBottomSheet extends StatefulWidget {
  final Function(int hotelID) onTapCallback;

  const AddSearchHotelBottomSheet({Key? key, required this.onTapCallback})
      : super(key: key);

  @override
  _AddSearchHotelBottomSheetState createState() =>
      _AddSearchHotelBottomSheetState();
}

class _AddSearchHotelBottomSheetState extends State<AddSearchHotelBottomSheet> {
  late final HotelsDialogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<HotelsDialogCubit>(context);
    _cubit.query.search = "";
    _cubit.search();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            left: 22,
            right: 22,
            bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            top: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Выберите отель",
              style: textStyle(size: 22, weight: Semibold6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SearchFieldBox(
              placeholder: "Поиск отеля",
              callback: (newValue) async {
                _cubit.query.search = newValue;
                await _cubit.search();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(234, 234, 234, 1),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: PaginationListView<HotelSearchState>(
                    cubit: _cubit,
                    itemBuilder: (context, models, index) {
                      final hotel = models[index];
                      return InkWell(
                        key: ValueKey(hotel.id),
                        onTap: () async {
                          await _cubit.selectHotel(index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: hotel.isSelected
                                ? const Color.fromRGBO(242, 99, 39, 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                style: textStyle(
                                  size: 18,
                                  weight: hotel.isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hotel.isSelected
                                      ? ColorOrange
                                      : ColorTextBlack,
                                ),
                              ),
                              Text(
                                "${hotel.country}, ${hotel.resort}",
                                style: textStyle(
                                  color: hotel.isSelected
                                      ? ColorOrange
                                      : const Color.fromRGBO(160, 160, 160, 1),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<HotelsDialogCubit, BaseCubitState>(
              bloc: _cubit,
              builder: (context, state) {
                return Row(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: DefaultButton(
                        title: "Выбрать",
                        textSize: 18,
                        enable: _cubit.selectedHotelID != -1,
                        scheme: DefaultButtonScheme.Orange,
                        onPressed: () {
                          widget.onTapCallback(_cubit.selectedHotelID);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                );
              },
            )
          ],
        ));
  }
}
