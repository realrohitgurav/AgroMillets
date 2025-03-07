import 'dart:async';
import 'dart:convert';

import 'package:agro_millets/core/home/application/comment_provider.dart';
import 'package:agro_millets/data/cache/app_cache.dart';
import 'package:agro_millets/models/comment.dart';
import "package:agro_millets/secrets.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CommentManager {
  final BuildContext context;
  late Timer timer;
  final WidgetRef ref;
  final String itemID;

  CommentManager(this.context, this.ref, this.itemID) {
    ref.read(commentProvider).updateItems([]);
    attach();
  }

  dispose() {
    debugPrint("CommentManager: Detaching Listeners...");
    timer.cancel();
    ref.read(commentProvider).updateItems([]);
  }

  // Using Polling instead of WebSockets
  attach() async {
    debugPrint("CommentManager: Attaching Listeners...");
    var data = await getAllComments();
    ref.read(commentProvider).updateItems(data);

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (context.mounted) {
          var data = await getAllComments();
          ref.read(commentProvider).updateItems(data);
        }
      },
    );
  }

  Future<List<CommentItem>> getAllComments() async {
    var response = await http.post(
      Uri.parse("$API_URL/list/getComments"),
      body: {"itemID": itemID},
    );
    debugPrint(response.body);
    Map data = json.decode(response.body);
    List dataMap = data["data"];
    List<CommentItem> list = [];

    for (var e in dataMap) {
      list.add(CommentItem.fromMap(e));
    }
    return list;
  }

  Future<void> addComment(String content) async {
    var response = await http.post(
      Uri.parse("$API_URL/list/comment"),
      body: {
        "itemID": itemID,
        "commentBy": appCache.authState.value.user!.id,
        "name": appCache.authState.value.user!.name,
        "content": content,
      },
    );
    debugPrint(response.body);
  }

  Future<void> addItem({
    required String name,
    required String listedBy,
    required String description,
    required List<String> images,
    required double price,
  }) async {
    var response = await http.post(
      Uri.parse("$API_URL/list/addItem"),
      headers: {"content-type": "application/json"},
      body: json.encode(
        {
          "listedBy": listedBy,
          "name": name,
          "description": description,
          "images": images,
          "price": price.toString(),
        },
      ),
    );
    print(response.body);
  }
}
