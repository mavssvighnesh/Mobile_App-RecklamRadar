import 'package:flutter/material.dart';

class LazyList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final int initialCount;
  final int loadMoreCount;
  final ScrollController? controller;

  const LazyList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 10,
    this.loadMoreCount = 5,
    this.controller,
  });

  @override
  State<LazyList<T>> createState() => _LazyListState<T>();
}

class _LazyListState<T> extends State<LazyList<T>> {
  late ScrollController _scrollController;
  int _displayedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _displayedItemCount = widget.initialCount.clamp(0, widget.items.length);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _displayedItemCount = (_displayedItemCount + widget.loadMoreCount)
          .clamp(0, widget.items.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedItemCount,
      itemBuilder: (context, index) {
        return widget.itemBuilder(context, widget.items[index]);
      },
    );
  }
} 