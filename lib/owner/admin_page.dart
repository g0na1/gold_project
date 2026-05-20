import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  final String shopId;
  final String shopName;

  const AdminPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  bool isLoading = false;

  String category = "Ring";
  String karat = "18";

  int quantity = 1;

  // 🔥 المصنعية لكل غرام
  double manufacturing = 4;

  final categories = [
    "Ring",
    "Necklace",
    "Bracelet",
    "Earrings",
  ];

  final karats = ["18", "21", "22", "24"];

  final quantityList = List.generate(20, (i) => i + 1);

  final manufacturingList = [
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
  ];

  static const mainColor = Color(0xffb8610b);

  // 🔥 تحويل الدولار إلى ريال عماني
  static const double usdToOmr = 0.384;

  // ======================================================
  // 🔥 جلب سعر الذهب من API حسب العيار
  // ======================================================

  Future<double> getGoldPrice(String selectedKarat) async {
    try {
      final response = await http.get(
        Uri.parse("https://api.gold-api.com/price/XAU"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // سعر الأونصة بالدولار
        double ouncePrice = data['price'];

        // سعر الغرام بالدولار
        double gramPrice = ouncePrice / 31.1035;

        // تحويل إلى ريال عماني
        double omrPrice = gramPrice * usdToOmr;

        switch (selectedKarat) {
          case "24":
            return omrPrice;

          case "22":
            return omrPrice * 0.916;

          case "21":
            return omrPrice * 0.875;

          case "18":
            return omrPrice * 0.750;

          default:
            return omrPrice;
        }
      }
    } catch (e) {
      print("Gold API Error: $e");
    }

    return 0;
  }

  // ======================================================
  // 🔥 حساب السعر النهائي
  // السعر = الوزن × (سعر الذهب + المصنعية)
  // ======================================================

  Future<double> calculatePrice(
    double weight,
    double manufacturing,
    String karat,
  ) async {
    // 🔥 سعر الذهب المتغير من API
    final goldPrice = await getGoldPrice(karat);

    // 🔥 المعادلة الجديدة
    return weight * (goldPrice + manufacturing);
  }

  // ======================================================
  // 🔥 إضافة منتج
  // ======================================================

  Future<void> addProduct() async {
    final name = nameController.text.trim();
    final image = imageController.text.trim();

    final weight =
        double.tryParse(weightController.text.trim()) ?? 0;

    if (name.isEmpty || image.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Check inputs ❌"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    // 🔥 حساب السعر النهائي
    final price = await calculatePrice(
      weight,
      manufacturing,
      karat,
    );

    // 🔥 جلب سعر الذهب الحالي أيضًا للتخزين
    final currentGoldPrice = await getGoldPrice(karat);

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('products')
        .add({
      'name': name,
      'image': image,
      'weight': weight,

      'karat': karat,

      // 🔥 المصنعية لكل غرام
      'manufacturing': manufacturing,

      'quantity': quantity,

      // 🔥 السعر النهائي
      'price': price,

      // 🔥 سعر الذهب وقت الإضافة
      'goldPrice': currentGoldPrice,

      'category': category,

      'adminId': user?.uid,

      'timestamp': FieldValue.serverTimestamp(),
    });

    nameController.clear();
    imageController.clear();
    weightController.clear();

    setState(() => isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product Added ✅"),
      ),
    );
  }

  // ======================================================
  // 🔥 حذف منتج
  // ======================================================

  Future<void> deleteProduct(String id) async {
    await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .collection('products')
        .doc(id)
        .delete();
  }
// ======================================================
// 🔥 تعديل منتج (UPDATE)
// ======================================================

Future<void> updateProduct(String id, Map<String, dynamic> oldData) async {
  final nameController =
      TextEditingController(text: oldData['name']);
  final imageController =
      TextEditingController(text: oldData['image']);
  final weightController =
      TextEditingController(text: oldData['weight'].toString());

  String editCategory = oldData['category'];
  String editKarat = oldData['karat'];
  int editQuantity = oldData['quantity'];
  double editManufacturing = oldData['manufacturing'];

  bool loading = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Product ✏️"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "Weight"),
                  ),
                  TextField(
                    controller: imageController,
                    decoration:
                        const InputDecoration(labelText: "Image URL"),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: editQuantity,
                    items: quantityList
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text("$e"),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => editQuantity = v!),
                    decoration:
                        const InputDecoration(labelText: "Quantity"),
                  ),

                  DropdownButtonFormField(
                    value: editManufacturing,
                    items: manufacturingList
                        .map((e) => DropdownMenuItem(
                              value: e.toDouble(),
                              child: Text("$e RO"),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => editManufacturing = v!),
                    decoration:
                        const InputDecoration(labelText: "Manufacturing"),
                  ),

                  DropdownButtonFormField(
                    value: editCategory,
                    items: categories
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => editCategory = v!),
                    decoration:
                        const InputDecoration(labelText: "Category"),
                  ),

                  DropdownButtonFormField(
                    value: editKarat,
                    items: karats
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setStateDialog(() => editKarat = v!),
                    decoration:
                        const InputDecoration(labelText: "Karat"),
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setStateDialog(() => loading = true);

                        final weight =
                            double.tryParse(weightController.text) ?? 0;

                        if (weight <= 0 ||
                            nameController.text.isEmpty ||
                            imageController.text.isEmpty) {
                          return;
                        }

                        final newPrice = await calculatePrice(
                          weight,
                          editManufacturing,
                          editKarat,
                        );

                        final goldPrice =
                            await getGoldPrice(editKarat);

                        await FirebaseFirestore.instance
                            .collection('shops')
                            .doc(widget.shopId)
                            .collection('products')
                            .doc(id)
                            .update({
                          'name': nameController.text.trim(),
                          'image': imageController.text.trim(),
                          'weight': weight,
                          'karat': editKarat,
                          'category': editCategory,
                          'quantity': editQuantity,
                          'manufacturing': editManufacturing,
                          'price': newPrice,
                          'goldPrice': goldPrice,
                        });

                        Navigator.pop(context);
                      },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}
  // ======================================================
  // 🔥 صورة المنتج
  // ======================================================

  Widget buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 55,
        height: 55,
        fit: BoxFit.cover,

        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;

          return const SizedBox(
            width: 55,
            height: 55,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          );
        },

        errorBuilder: (c, e, s) => Container(
          width: 55,
          height: 55,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  // ======================================================
  // 🔥 UI
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        backgroundColor: mainColor,
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // =========================================
              // 🔥 ADD PRODUCT
              // =========================================

              Card(
                elevation: 6,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(12),

                  child: Column(
                    children: [

                      const Text(
                        "Add Product ✨",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),

                      TextField(
                        controller: nameController,

                        decoration: const InputDecoration(
                          labelText: "Name",
                        ),
                      ),

                      TextField(
                        controller: weightController,

                        keyboardType:
                            TextInputType.number,

                        decoration: const InputDecoration(
                          labelText: "Weight",
                        ),
                      ),

                      TextField(
                        controller: imageController,

                        decoration: const InputDecoration(
                          labelText: "Image URL",
                        ),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField(
                        value: quantity,

                        decoration: const InputDecoration(
                          labelText: "Quantity",
                        ),

                        items: quantityList
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text("$e"),
                              ),
                            )
                            .toList(),

                        onChanged: (v) =>
                            setState(() => quantity = v!),
                      ),

                      DropdownButtonFormField(
                        value: manufacturing,

                        decoration: const InputDecoration(
                          labelText:
                              "Manufacturing Per Gram",
                        ),

                        items: manufacturingList
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.toDouble(),
                                child: Text("$e RO"),
                              ),
                            )
                            .toList(),

                        onChanged: (v) => setState(
                          () => manufacturing = v!,
                        ),
                      ),

                      DropdownButtonFormField(
                        value: category,

                        decoration: const InputDecoration(
                          labelText: "Category",
                        ),

                        items: categories
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),

                        onChanged: (v) =>
                            setState(() => category = v!),
                      ),

                      DropdownButtonFormField(
                        value: karat,

                        decoration: const InputDecoration(
                          labelText: "Karat",
                        ),

                        items: karats
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ),
                            )
                            .toList(),

                        onChanged: (v) =>
                            setState(() => karat = v!),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          minimumSize:
                              const Size(double.infinity, 45),
                        ),

                        onPressed:
                            isLoading ? null : addProduct,

                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Add Product",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================================
              // 🔥 PRODUCTS
              // =========================================

              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .doc(widget.shopId)
                    .collection('products')
                    .orderBy(
                      'timestamp',
                      descending: true,
                    )
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child:
                            CircularProgressIndicator(),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child:
                            Text("No products yet 🛒"),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount: docs.length,

                    itemBuilder: (context, i) {
                      final data = docs[i].data();

                      final id = docs[i].id;

                      return Card(
                        child: ListTile(
                          onTap: () => updateProduct(id, data),
                          leading:
                              buildImage(data['image'] ?? ""),

                          title:
                              Text(data['name'] ?? ""),

                          subtitle: Text(
                            "${(double.tryParse(data['price'].toString()) ?? 0).toStringAsFixed(2)} RO • Qty: ${data['quantity']}",
                          ),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),

                            onPressed: () =>
                                deleteProduct(id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}