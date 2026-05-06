import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:psn.hotels.hub/presentation/blocks/base_cubit/base_cubit.dart';
import 'package:psn.hotels.hub/presentation/blocks/list_cubit.dart';
import 'package:psn.hotels.hub/presentation/items/loading_more_indicator.dart';
import 'package:psn.hotels.hub/presentation/ui_helper.dart';

import 'loading_indicator.dart';

class PaginationListView<Model> extends StatefulWidget {
  final ListCubit cubit;
  final Widget? Function(BuildContext, List<Model>, int) itemBuilder;
  final ScrollController? scrollController; // Сделали опциональным
  final Widget Function(BuildContext, int)? separatorBuilder;
  final Widget? emptyViewPlug;
  final Widget? emptySearchViewPlug;
  final Widget? errorViewPlug;
  final bool poolToRefresh;
  final Axis scrollDirection;
  final bool reverse;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final Widget? header;

  PaginationListView(
      {Key? key,
      required this.cubit,
      required this.itemBuilder,
      this.scrollController,
      this.separatorBuilder,
      this.scrollDirection = Axis.vertical,
      this.reverse = false,
      this.shrinkWrap = false,
      this.emptyViewPlug,
      this.emptySearchViewPlug,
      this.errorViewPlug,
      this.padding,
      this.poolToRefresh = true,
      this.floatingActionButton,
      this.header})
      : super(key: key);

  @override
  State<PaginationListView<Model>> createState() =>
      _PaginationListViewState<Model>();
}

class _PaginationListViewState<Model> extends State<PaginationListView<Model>> {
  late ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    // Используем переданный контроллер или создаем свой
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    // Закрываем контроллер только если мы его сами создали
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      bloc: widget.cubit,
      builder: (context, state) {
        List<Model> currentModels = [];
        if (state is SuccessListState<Model>) {
          currentModels = state.models;
        }

        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              child: widget.poolToRefresh == true
                  ? _buildRefreshIndicator(currentModels)
                  : _buildListView(currentModels),
              onNotification: (notification) =>
                  _onNotification(notification, state as BaseCubitState),
            ),
            if (state is LoadingState)
              LoadingIndicatorWidget()
            else if (state is LoadingMoreState)
              LoadingMoreInsicator(
                  alignment: widget.reverse == false
                      ? Alignment.bottomCenter
                      : Alignment.topCenter)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                widget.emptyViewPlug != null &&
                widget.cubit.query.is_searching == false)
              Center(child: widget.emptyViewPlug)
            else if (state is SuccessListState &&
                state.models.length == 0 &&
                widget.emptySearchViewPlug != null &&
                widget.cubit.query.is_searching == true)
              Center(child: widget.emptySearchViewPlug)
            else if (state is ErrorState && widget.errorViewPlug != null)
              Center(child: widget.errorViewPlug)
            else if (state is ErrorState && widget.errorViewPlug == null)
              Center(child: Text('Error: ${state.error}')),
            if (widget.floatingActionButton != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: AnimatedScale(
                  scale: _isFabVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: widget.floatingActionButton!,
                ),
              ),
          ],
        );
      },
      listener: (context, state) {
        if (state is ErrorState) {
          showSnackBar(context: context, message: state.error ?? "Empty");
        }
        if (state is SuccessListState &&
            widget.cubit.query.currentPage < widget.cubit.query.lastPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients &&
                _scrollController.position.maxScrollExtent < 100) {
              widget.cubit.loadMore();
            }
          });
        }
      },
    );
  }

  Widget _buildRefreshIndicator(List<Model> models) {
    return RefreshIndicator(
      onRefresh: widget.cubit.refresh,
      child: _buildListView(models),
    );
  }

  Widget _buildListView(List<Model> models) {
    Widget listView;
    if (widget.separatorBuilder != null) {
      listView = ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        shrinkWrap: widget.shrinkWrap,
        itemCount: models.length + (widget.header != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.header != null && index == 0) {
            return widget.header!;
          }

          final modelIndex = widget.header != null ? index - 1 : index;
          return widget.itemBuilder(context, models, modelIndex);
        },
        separatorBuilder: widget.separatorBuilder!,
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: AlwaysScrollableScrollPhysics(),
        scrollDirection: widget.scrollDirection,
        reverse: widget.reverse,
        shrinkWrap: widget.shrinkWrap,
        itemCount: models.length,
        itemBuilder: (context, index) =>
            widget.itemBuilder(context, models, index),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: listView,
    );
  }

  bool _onNotification(ScrollNotification notification, BaseCubitState state) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    }

    if (notification is! ScrollUpdateNotification) return false;

    final bool canLoadMore = state is! LoadingState &&
        state is! LoadingMoreState &&
        widget.cubit.query.currentPage < widget.cubit.query.lastPage;

    if (canLoadMore) {
      final metrics = notification.metrics;
      if (metrics.extentAfter <= 300 && metrics.maxScrollExtent > 0) {
        widget.cubit.loadMore();
      }
    }

    return false;
  }
}
