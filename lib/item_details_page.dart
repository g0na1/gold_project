import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reserve_page.dart';

class ItemDetailsPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String shopId;
  final String productId;

  const ItemDetailsPage({
    super.key,
    required this.item,
    required this.shopId,
    required this.productId,
  });

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {

  bool isFavorite = false;

  // 🔥 ADD TO FAVORITES
  Future<void> addToFavorites(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(widget.productId);

    final doc = await ref.get();

    // 🔥 prevent duplicate
    if (doc.exists) {
      setState(() {
        isFavorite = true;
      });

      return;
    }

    await ref.set({
      ...data,
      'productId': widget.productId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      isFavorite = true;
    });
  }

  // 🔥 INFO ROW WIDGET
  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value.isEmpty ? "N/A" : value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xffb8610b);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item["name"] ?? ""),
        backgroundColor: mainColor,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shops')
            .doc(widget.shopId)
            .collection('products')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final quantity = data['quantity'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔥 IMAGE CARD
                Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        data["image"] ?? "",
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 NAME
                Text(
                  data["name"] ?? "No Name",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔥 PRICE
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.monetization_on,
                      color: Colors.green,
                    ),
                    title: Text(
                      "${double.parse(data['price'].toString()).toStringAsFixed(2)} RO",
                    ),
                    subtitle: const Text("Current Price"),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔥 DETAILS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        infoRow(
                          "Weight",
                          "${data["weight"] ?? "N/A"} g",
                        ),

                        infoRow(
                          "Karat",
                          "${data["karat"] ?? "N/A"}",
                        ),

                        infoRow(
                          "Category",
                          "${data["category"] ?? "N/A"}",
                        ),

                        infoRow(
                          "Manufacturing",
                          "${data["manufacturing"] ?? "N/A"}",
                        ),

                        infoRow(
                          "Available",
                          "$quantity",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 OUT OF STOCK
                if (quantity == 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Out of Stock",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )

                else
                  Column(
                    children: [

                      // 🔥 RESERVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            padding:
                                const EdgeInsets.all(14),
                          ),

                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReservePage(
                                  item: data,
                                  shopId: widget.shopId,
                                  productId:
                                      widget.productId,
                                ),
                              ),
                            );
                          },

                          child: const Text(
                            "Reserve Now",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔥 FAVORITE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(

                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : null,
                          ),

                          label: Text(
                            isFavorite
                                ? "Added to Favorites"
                                : "Add to Favorites",
                          ),

                          onPressed: () async {

                            await addToFavorites(data);

                            ScaffoldMessenger.of(context)
                                .showSnackBar(

                              SnackBar(
                                content: Text(
                                  isFavorite
                                      ? "Added to Favorites Successfully"
                                      : "Already in Favorites",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}