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
            NotificationListener<ScrollNotification>(
              child: poolToRefresh == true
                  ? _buildRefreshIndicator()
                  : _buildListView(),
              onNotification: (notification) => _onNotification(
                  notification: notification, state: state as BaseCubitState),
            ),
            if (state is LoadingState)
              DefaultFullScreenIndicator
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
        // Если данные загрузились, но список всё еще слишком короткий, чтобы его можно было скроллить,
        // и при этом в базе есть еще страницы - подгружаем следующую автоматически.
        if (state is SuccessListState &&
            cubit.query.currentPage < cubit.query.lastPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients &&
                scrollController.position.maxScrollExtent < 100) {
              cubit.loadMore();
            }
          });
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
    Widget listView;
    if (separatorBuilder != null) {
      listView = ListView.separated(
        controller: scrollController,
        padding: padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: scrollDirection,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        itemCount: cubit.modelsLength,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
      );
    } else {
      listView = ListView.builder(
        controller: scrollController,
        padding: padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: scrollDirection,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        itemCount: cubit.modelsLength,
        itemBuilder: itemBuilder,
      );
    }

    return Scrollbar(
      controller: scrollController,
      child: listView,
    );
  }

  bool _onNotification(
      {required ScrollNotification notification,
      required BaseCubitState state}) {
    if (notification is! ScrollUpdateNotification) return false;

    final bool canLoadMore = state is! LoadingState &&
        state is! LoadingMoreState &&
        cubit.query.currentPage < cubit.query.lastPage;

    if (canLoadMore) {
      final metrics = notification.metrics;
      // Если до конца списка осталось меньше 300 пикселей
      if (metrics.extentAfter <= 300 && metrics.maxScrollExtent > 0) {
        cubit.loadMore();
      }
    }

    return true;
  }

//   bool _onNotification(
//       {required ScrollNotification notification,
//         required BaseCubitState state}) {
//     if (state is! LoadingState &&
//         state is! LoadingMoreState &&
//         notification is ScrollUpdateNotification) {
//       if (scrollController.position.extentAfter <= 300 &&
//           scrollController.position.maxScrollExtent >= 20) {
//         debugPrint("was loadMore from pagination list view");
//         cubit.loadMore();
//       }
//     }
//
//     return true;
//   }
// }
}
