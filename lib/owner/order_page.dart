import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPage extends StatelessWidget {
  final String shopId;

  const OrderPage({super.key, required this.shopId});

  // 🔥 تحويل الوقت إلى ساعة:دقيقة
  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$hour:$minute";
  }

  Future<void> updateOrderStatus(
    String orderId,
    Map<String, dynamic> data,
    String status,
  ) async {
    final userId = data['userId'];

    // 1. تحديث الطلب في shop
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('orders')
        .doc(orderId)
        .update({
      "status": status,
    });

    // 2. تحديث الطلب في user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .set({
      ...data,
      "status": status,
    });

    // 3. 🔥 خصم الكمية فقط عند القبول
    if (status == "accepted") {
      final productId = data['productId'];

      final productRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId);

      final productSnap = await productRef.get();

      if (productSnap.exists) {
        final currentQty = productSnap['quantity'] ?? 0;
        final orderQty = data['quantity'] ?? 1;

        final newQty = currentQty - orderQty;

        await productRef.update({
          "quantity": newQty < 0 ? 0 : newQty,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xffb8610b);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .collection('orders')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!.docs;

            if (orders.isEmpty) {
              return const Center(child: Text("No orders yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final doc = orders[index];
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? "pending";

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [

                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['image'] ?? "",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                          title: Text(
                            data['productName'] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text("${data['price']} RO"),
                              Text("User: ${data['userEmail']}"),

                              // 🔥 وقت الطلب
                              if (data['timestamp'] != null)
                                Text(
                                  "Time: ${formatTime(data['timestamp'])}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),

                              const SizedBox(height: 6),

                              // 🔥 رسالة المستخدم
                              if (data['message'] != null &&
                                  data['message']
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "💬 ${data['message']}",
                                  ),
                                ),

                              const SizedBox(height: 5),

                              Text(
                                "Status: $status",
                                style: TextStyle(
                                  color: status == "accepted"
                                      ? Colors.green
                                      : status == "rejected"
                                          ? Colors.red
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (status == "pending")
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () => updateOrderStatus(
                                  doc.id,
                                  data,
                                  "accepted",
                                ),
                                child: const Text("Accept"),
                              ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => updateOrderStatus(
                                  doc.id,
                                  data,
                                  "rejected",
                                ),
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}