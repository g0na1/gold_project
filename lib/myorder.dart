import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // 🔥 تحديث الوقت كل دقيقة
    timer = Timer.periodic(const Duration(minutes: 1), (t) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String getRemainingTime(Timestamp timestamp) {
    final orderTime = timestamp.toDate();
    final expiryTime = orderTime.add(const Duration(hours: 24));
    final now = DateTime.now();

    final difference = expiryTime.difference(now);

    if (difference.isNegative) {
      return "Expired";
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return "${hours}h ${minutes}m left";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: const Color(0xffb8610b),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No orders yet"),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(
                    data['image'] ?? "",
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.image_not_supported),
                  ),

                  title: Text(data['productName'] ?? ""),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔥 STATUS
                      Text(
                        "Status: ${data['status'] ?? "pending"}",
                        style: TextStyle(
                          color: data['status'] == "accepted"
                              ? Colors.green
                              : data['status'] == "rejected"
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 🔥 TIME LEFT
                      Text(
                        data['timestamp'] == null
                            ? "Loading..."
                            : getRemainingTime(data['timestamp']),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}