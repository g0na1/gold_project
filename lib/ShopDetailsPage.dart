import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details_page.dart';

class ShopDetailsPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ShopDetailsPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  String selectedCategory = "All";
  String selectedSort = "Newest";

  final categories = ["All", "Ring", "Necklace", "Bracelet", "Earrings"];
  final sorts = ["Newest", "Price Low", "Price High"];

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xffb8610b);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        centerTitle: true,
        backgroundColor: mainColor,
      ),

      body: Column(
        children: [

          // 🔥 FILTER BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: categories
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCategory = val!;
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedSort,
                    decoration: InputDecoration(
                      labelText: "Sort",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: sorts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedSort = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔥 PRODUCTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shops')
                  .doc(widget.shopId)
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                // 🔥 FILTER
                if (selectedCategory != "All") {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['category'] ?? "") == selectedCategory;
                  }).toList();
                }

                // 🔥 SORT
                if (selectedSort == "Price Low") {
                  docs.sort((a, b) =>
                      (a['price'] ?? 0).compareTo(b['price'] ?? 0));
                } else if (selectedSort == "Price High") {
                  docs.sort((a, b) =>
                      (b['price'] ?? 0).compareTo(a['price'] ?? 0));
                } else {
                  docs.sort((a, b) {
                    final t1 = a['timestamp'];
                    final t2 = b['timestamp'];
                    if (t1 == null || t2 == null) return 0;
                    return t2.compareTo(t1);
                  });
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final productId = docs[index].id;
                    final quantity = data['quantity'] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsPage(
                              item: data,
                              shopId: widget.shopId,
                              productId: productId, // 🔥 مهم جداً
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [

                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(15)),
                              child: Image.network(
                                data['image'] ?? "",
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  );
                                },
                              ),
                            ),

                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      data['name'] ?? "",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),

                                    const SizedBox(height: 8),

                                   Text(
  "Price: ${(data['price'] ?? 0).toStringAsFixed(2)} RO",
  style: const TextStyle(
    color: mainColor,
    fontWeight: FontWeight.bold,
  ),
),

                                    Text(
                                      data['category'] ?? "",
                                      style: const TextStyle(
                                          color: Colors.grey),
                                    ),

                                    const SizedBox(height: 5),

                                    // 🔥 الكمية
                                    Text(
                                      quantity > 0
                                          ? "Available: $quantity"
                                          : "Out of stock",
                                      style: TextStyle(
                                        color: quantity > 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}