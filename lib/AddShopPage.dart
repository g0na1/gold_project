import 'package:act3/owner/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddShopPage extends StatefulWidget {
  final String adminId;

  const AddShopPage({super.key, required this.adminId});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  bool isLoading = false;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> addShop() async {
    final name = nameController.text.trim();
    final location = locationController.text.trim();
    final image = imageController.text.trim();

    if (name.isEmpty || location.isEmpty || image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields ❌")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔥 CHECK: هل هذا الإيميل عنده متجر مسبقًا؟
      final existingShop = await FirebaseFirestore.instance
          .collection('shops')
          .where('email', isEqualTo: user?.email)
          .get();

      if (existingShop.docs.isNotEmpty) {
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You already have a shop with this email ❌"),
          ),
        );
        return;
      }

      // 🔥 إنشاء المتجر
      DocumentReference shopRef =
          await FirebaseFirestore.instance.collection('shops').add({
        'name': name,
        'location': location,
        'image': image,
        'adminId': widget.adminId,
        'email': user?.email, // مهم لمنع التكرار
        'createdAt': Timestamp.now(),
      });

      // 🔥 تحديث بيانات الأدمن
      await FirebaseFirestore.instance
          .collection('admin')
          .doc(widget.adminId)
          .update({
        'shopId': shopRef.id,
        'shopName': name,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop added successfully ✅")),
      );

      // 🔥 الانتقال للهوم
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePageUI(
            shopId: shopRef.id,
            shopName: name,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Shop"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Shop Name"),
            ),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: "Image URL"),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: isLoading ? null : addShop,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Shop"),
            ),
          ],
        ),
      ),
    );
  }
}