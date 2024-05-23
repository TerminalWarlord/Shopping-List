import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_app/data/categories.dart';

import 'package:shopping_app/models/grocery_item.dart';
import 'package:shopping_app/widgets/credentials.dart';
import 'package:shopping_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = baseUrl;
    try {
      final response = await http.get(url);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> resData = jsonDecode(response.body);
      List<GroceryItem> loadedList = [];
      for (final item in resData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => item.value['category'] == element.value.name)
            .value;
        loadedList.add(
          GroceryItem(
              id: item.key,
              name: item.value['name'],
              quantity: item.value['quantity'],
              category: category),
        );
      }
      setState(() {
        _groceryItems = loadedList;
      });
    } catch (e) {
      _error = 'Failed to fetch data!';
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(context,
        MaterialPageRoute(builder: (ctx) {
      return const NewItem();
    }));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(int index) {
    final url = getDeleteUrl(_groceryItems[index].id);
    try {
      http.delete(url);
      setState(() {
        _groceryItems.remove(_groceryItems[index]);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item has been removed!"),
        ),
      );
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) {
          return Dismissible(
            key: ValueKey(_groceryItems[index]),
            onDismissed: (direction) {
              _removeItem(index);
            },
            background: Container(
              color: Colors.redAccent,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        color: _groceryItems[index].category.color,
                        width: 15,
                        height: 15,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Text(_groceryItems[index].name),
                    ],
                  ),
                  Text(
                    _groceryItems[index].quantity.toString(),
                  ),
                ],
              ),
            ),
          );
        });

    if (_error != null) {
      content = Center(
        child: Text(
          _error!,
        ),
      );
    } else if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_groceryItems.isEmpty) {
      content = const Center(
        child: Text(
          "Nothing in the card! Add something.",
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
