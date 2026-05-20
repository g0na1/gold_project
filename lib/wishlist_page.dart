import 'package:flutter/material.dart';

class WishlistPage extends StatelessWidget {
  final List<String> wishlistItems = [
    "Ring 1 - 55.3 RO",
    "Necklace 1 - 120.5 RO",
    "Earring 1 - 48.9 RO"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wishlist"),
        backgroundColor: Colors.amber,
      ),
      body: ListView.builder(
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.favorite, color: Colors.red),
            title: Text(wishlistItems[index]),
            trailing: Icon(Icons.shopping_cart),
          );
        },
      ),
    );
  }
}