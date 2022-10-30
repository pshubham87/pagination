// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:path_provider/path_provider.dart';
import 'model/post_items.dart';
import 'model/post_model.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InfiniteScrollPaginatorDemo extends StatefulWidget {
  @override
  _InfiniteScrollPaginatorDemoState createState() =>
      _InfiniteScrollPaginatorDemoState();
}

class _InfiniteScrollPaginatorDemoState
    extends State<InfiniteScrollPaginatorDemo> {
  late Box box;

  // Future openBox() async {
  //   var dir = await getApplicationDocumentsDirectory();
  //   Hive.init(dir.path);
  //   box = await Hive.openBox("data");
  // }

  final _numberOfPostsPerRequest = 15;
  final PagingController<int, Post> _pagingController =
      PagingController(firstPageKey: 0);

  bool _error = false;

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    // await openBox();
    try {
      final response = await get(Uri.parse(
          "https://api.github.com/users/JakeWharton/repos?page=$pageKey&per_page=15"));
      List responseList = json.decode(response.body);
      // await putdata(responseList);
      List<Post> postList = responseList
          .map((data) => Post(
                data['description'] ?? " ",
                data['name'] ?? " ",
                data['language'] ?? " ",
                data['watchers_count'] ?? " ",
                data['open_issues'] ?? " ",
              ))
          .toList();

      final isLastPage = postList.length < _numberOfPostsPerRequest;
      if (isLastPage) {
        _pagingController.appendLastPage(postList);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(postList, nextPageKey);
      }
    } catch (e) {
      print('$e');
    }

    // var mymap = box.toMap().values.toList();
    // if (mymap.isEmpty) {
    //   data.add("empty");
    // } else {
    //   data = mymap;
    // }
  }

  // Future putdata(data) async {
  //   await box.clear();
  //   for (var d in data) {
  //     box.add(d);
  //   }
  // }

  Widget errorDialog({required double size}) {
    return SizedBox(
      height: 180,
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'An error occurred when fetching the posts.',
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "jake's Git",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 25,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: Scrollbar(
          thickness: 7,
          child: PagedListView<int, Post>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<Post>(
                itemBuilder: (context, item, index) {
              if (index == PostItem) {
                if (_error) {
                  return Center(child: errorDialog(size: 15));
                } else {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ));
                }
              }
              return PostItem(
                item.description,
                item.name,
                item.language,
                item.watchers_count,
                item.open_issues,
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
