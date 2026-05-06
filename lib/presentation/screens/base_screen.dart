import 'package:flutter/material.dart';
import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';

import '../items/loading_indicator.dart';

class BaseScreen extends StatelessWidget {
  final Widget? child;
  final BaseCubitState? state;
  final ScrollController? scrollController;

  const BaseScreen({
    Key? key,
    required this.child,
    this.state,
    this.scrollController,
  })  : assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraint) {
            return SingleChildScrollView(
              controller: scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: child,
                ),
              ),
            );
          },
        ),
        if (state is LoadingState) const LoadingIndicatorWidget()
      ],
    );
  }
}
