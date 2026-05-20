import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservePage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String shopId;
  final String productId;

  const ReservePage({
    super.key,
    required this.item,
    required this.shopId,
    required this.productId,
  });

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  bool isLoading = false;

  final TextEditingController messageController = TextEditingController();

  Future<void> sendOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    final productRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('products')
        .doc(widget.productId);

    try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
  final snapshot = await transaction.get(productRef);

  final currentQty = snapshot['quantity'];

  if (currentQty <= 0) {
    throw Exception("Out of stock");
  }

  final orderRef = FirebaseFirestore.instance
      .collection('shops')
      .doc(widget.shopId)
      .collection('orders')
      .doc();

  transaction.set(orderRef, {
    'userId': user.uid,
    'userEmail': user.email,
    'productName': widget.item['name'],
    'price': widget.item['price'],
    'image': widget.item['image'],
    'message': messageController.text.trim(),
    'status': 'pending',
    'quantity': 1, // مهم
    'productId': widget.productId,
    'timestamp': FieldValue.serverTimestamp(),
  });
});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order sent successfully ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void confirmOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Order"),
        content: const Text("Do you want to send this reservation?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              sendOrder();
            },
            child: const Text("Confirm"),
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
        title: const Text("Reserve Product"),
        backgroundColor: mainColor,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔥 PRODUCT INFO
            Card(
              child: Column(
                children: [

                  Image.network(
                    widget.item["image"] ?? "",
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          widget.item["name"] ?? "",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 5),

                       Text(
  "Price: ${double.parse(widget.item["price"].toString()).toStringAsFixed(2)} RO",
),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 MESSAGE BOX (NEW)
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Message to seller (optional)",
                border: OutlineInputBorder(),
                hintText: "Write any note for the owner...",
              ),
            ),

            const Spacer(),

            // 🔥 BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: isLoading ? null : confirmOrder,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send Reservation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}