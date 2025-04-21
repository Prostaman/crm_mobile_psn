import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/ui/items/loading_more_indicator.dart';
import 'package:psn.hotels.hub/helpers/ui_helper.dart';

class PaginationListView extends StatelessWidget {
  final ScrollController scrollController;

  final ListCubit cubit;
  final Widget? Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int)? separatorBuilder;

  final Widget? emptyViewPlug;
  final Widget? emptySearchViewPlug;
  final Widget? errorViewPlug;

  final bool poolToRefresh = true;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  PaginationListView(
      {Key? key,
      required this.cubit,
      required this.itemBuilder,
      required this.scrollController,
      this.separatorBuilder,
      this.scrollDirection = Axis.vertical,
      this.reverse = false,
      this.shrinkWrap = false,
      this.emptyViewPlug,
      this.emptySearchViewPlug,
      this.errorViewPlug,
      this.padding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      bloc: cubit,
      builder: (context, state) {
        return Stack(
          children: [
            NotificationListener(
              child: poolToRefresh == true ? _buildRefreshIndicator() : _buildListView(),
              // onNotification: (notification) => _onNotification(
              //     notification: notification, state: state as BaseCubitState),
            ),
            if (state is LoadingState)
              DefaultFullScreenIndicator
            else if (state is LoadingMoreState)
              LoadingMoreInsicator(alignment: reverse == false ? Alignment.bottomCenter : Alignment.topCenter)
            else if (state is SuccessListState && state.models.length == 0 && emptyViewPlug != null && cubit.query.searching == false)
              Center(child: emptyViewPlug)
            else if (state is SuccessListState && state.models.length == 0 && emptySearchViewPlug != null && cubit.query.searching == true)
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
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: scrollController,
        padding: padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: scrollDirection,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        itemCount: cubit.modelsLanght,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        padding: padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: scrollDirection,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        itemCount: cubit.modelsLanght,
        itemBuilder: itemBuilder,
      );
    }
  }

  // bool _onNotification(
  //     {required var notification, required BaseCubitState state}) {
  //   if (!(state is LoadingState) &&
  //       !(state is LoadingMoreState) &&
  //       notification is ScrollNotification) {
  //     // if (scrollController.position.extentAfter <= 400 &&
  //     //     scrollController.position.maxScrollExtent >= 20) {
  //       cubit.loadMore();
  //       print("was loadMore from pagination list view");
  //       // print(_scrollController.position.maxScrollExtent);
  //       return false;

  //   }

  //   return true;
  // }
}
