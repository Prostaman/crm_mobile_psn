import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/data/models/entities_database/file_model.dart';
import 'media_item_builder.dart';

class FilterCarousel extends StatelessWidget {
  final List<List<double>> filters;
  final FileModel currentFile;
  final int currentIndexOfFilter;
  final Function(int) onFilterSelected;

  const FilterCarousel({
    Key? key,
    required this.filters,
    required this.currentFile,
    required this.currentIndexOfFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Высота карусели
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Горизонтальная прокрутка
        itemCount: filters.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () => onFilterSelected(index),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(filters[index]),
                child: buildMediaItem(currentFile),
              ),
            ),
          );
        },
      ),
    );
  }
}
