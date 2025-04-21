import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/ui/items/loading_more_indicator.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class PaginationGridView extends StatelessWidget {
  final ScrollController scrollController;

  final ListCubit cubit;
  final Widget? Function(BuildContext, int) itemBuilder;

  final Widget? emptyViewPlug;
  final Widget? emptySearchViewPlug;
  final Widget? errorViewPlug;

  final bool poolToRefresh = true;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final bool appendToLast;

  PaginationGridView({
    Key? key,
    required this.cubit,
    required this.itemBuilder,
    ScrollController? scrollController,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.shrinkWrap = false,
    this.emptyViewPlug,
    this.emptySearchViewPlug,
    this.errorViewPlug,
    this.padding,
    this.physics,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 0.0,
    this.appendToLast = false,
  })  : this.scrollController = scrollController ?? ScrollController(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      bloc: cubit,
      builder: (context, state) {
        return Stack(
          children: [
              if (state is BaseCubitState)
            NotificationListener(
              child: poolToRefresh == true ? _buildRefreshIndicator() : _buildListView(),
              onNotification: (notification) => _onNotification(notification: notification, state: state ),
            ),
            if (state is LoadingState)
            Center(
              child: Container(
                height: 200,
                child: Center(
                  child: DefaultIndicator
                )
              )
            )
              // DefaultFullScreenIndicator
            else if (state is LoadingMoreState)
              LoadingMoreInsicator(alignment: reverse == false ? Alignment.bottomCenter : Alignment.topCenter)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                emptyViewPlug != null &&
                cubit.query.searching == false)
              Center(child: emptyViewPlug)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                emptySearchViewPlug != null &&
                cubit.query.searching == true)
              Center(child: emptySearchViewPlug)
            else if (state is ErrorState && errorViewPlug != null)
              Center(child: errorViewPlug),
          ],
        );
      },
      listener: (context, state) {
        if (state is ErrorState) {
          showSnackBar(context: context, message: state.error ?? "Empty");
        }
      },
    );
  }

  Widget _buildRefreshIndicator() {
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: _buildListView(),
    );
  }

  Widget _buildListView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: itemBuilder,
      controller: scrollController,
      padding: padding,
      physics: physics != null ? physics : AlwaysScrollableScrollPhysics(),
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      itemCount: appendToLast == true ? cubit.modelsLanght + 1 : cubit.modelsLanght,
    );
  }

  bool _onNotification({required var notification, required BaseCubitState state}) {
    if (!(state is LoadingState) && !(state is LoadingMoreState) && notification is ScrollNotification) {
      // if (notification is ScrollEndNotification) {
      if (scrollController.position.extentAfter <= 400 && scrollController.position.maxScrollExtent >= 20) {
        cubit.loadMore();

        // print(_scrollController.position.maxScrollExtent);

        return false;
      }
      // }
    }

    return true;
  }
}
