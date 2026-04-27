import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/ui/items/loading_more_indicator.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class PaginationGridView<Model> extends StatelessWidget {
  final ScrollController scrollController;

  final ListCubit cubit;
  final Widget? Function(BuildContext, List<Model>, int) itemBuilder;

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
        List<Model> currentModels = [];
        if (state is SuccessListState<Model>) {
          currentModels = state.models;
        }

        return Stack(
          children: [
            if (state is BaseCubitState)
              NotificationListener<ScrollNotification>(
                child: poolToRefresh == true
                    ? _buildRefreshIndicator(currentModels)
                    : _buildListView(currentModels),
                onNotification: (notification) =>
                    _onNotification(notification: notification, state: state),
              ),
            if (state is LoadingState)
              Center(
                  child: Container(
                      height: 200, child: Center(child: DefaultIndicator)))
            else if (state is LoadingMoreState)
              LoadingMoreInsicator(
                  alignment: reverse == false
                      ? Alignment.bottomCenter
                      : Alignment.topCenter)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                emptyViewPlug != null &&
                cubit.query.is_searching == false)
              Center(child: emptyViewPlug)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                emptySearchViewPlug != null &&
                cubit.query.is_searching == true)
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

  Widget _buildRefreshIndicator(List<Model> models) {
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: _buildListView(models),
    );
  }

  Widget _buildListView(List<Model> models) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => itemBuilder(context, models, index),
      controller: scrollController,
      padding: padding,
      physics: physics ?? AlwaysScrollableScrollPhysics(),
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      itemCount: appendToLast == true ? models.length + 1 : models.length,
    );
  }

  bool _onNotification(
      {required ScrollNotification notification,
      required BaseCubitState state}) {
    if (state is! LoadingState &&
        state is! LoadingMoreState &&
        notification is ScrollUpdateNotification) {
      if (scrollController.position.extentAfter <= 400 &&
          scrollController.position.maxScrollExtent >= 20) {
        cubit.loadMore();
        return false;
      }
    }

    return true;
  }
}
