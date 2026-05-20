import 'package:act3/AddShopPage.dart';
import 'package:act3/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_page.dart';
import 'order_page.dart';
import 'profilepage.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:fl_chart/fl_chart.dart';

class HomePageUI extends StatefulWidget {
  final String shopId;
  final String shopName;

  const HomePageUI({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<HomePageUI> createState() => _HomePageUIState();
}

class _HomePageUIState extends State<HomePageUI> {
  int currentIndex = 0;

  String shopName = "";
  String ownerName = "";

  Timer? goldTimer;

  bool isLoadingGold = true;

  static const double usdToOmr = 0.384;

  double gold24K = 0;
  double gold22K = 0;
  double gold21K = 0;
  double gold18K = 0;

  List<double> gold24History = [];
  List<double> gold22History = [];
  List<double> gold21History = [];
  List<double> gold18History = [];

  // الأيام
  List<String> daysHistory = [];

  @override
  void initState() {
    super.initState();

    getOwnerName();

    if (widget.shopId.isNotEmpty) {
      getShopName();
    } else {
      shopName = "No Shop Yet";
    }

    fetchGoldPrice();

    goldTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => fetchGoldPrice(),
    );
  }

  @override
  void dispose() {
    goldTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchGoldPrice() async {
    try {
      final response =
          await http.get(Uri.parse("https://api.gold-api.com/price/XAU"));

      if (response.statusCode != 200) {
        setState(() => isLoadingGold = false);
        return;
      }

      final data = jsonDecode(response.body);

      double ouncePrice = data['price'];
      double pricePerGram = ouncePrice / 31.1035;

      setState(() {
        gold24K = pricePerGram * usdToOmr;
        gold22K = pricePerGram * 0.916 * usdToOmr;
        gold21K = pricePerGram * 0.875 * usdToOmr;
        gold18K = pricePerGram * 0.750 * usdToOmr;

        gold24History.add(gold24K);
        gold22History.add(gold22K);
        gold21History.add(gold21K);
        gold18History.add(gold18K);

        final now = DateTime.now();
        daysHistory.add("${now.day}/${now.month}");

        if (gold24History.length > 30) {
          gold24History.removeAt(0);
          gold22History.removeAt(0);
          gold21History.removeAt(0);
          gold18History.removeAt(0);
          daysHistory.removeAt(0);
        }

        isLoadingGold = false;
      });
    } catch (e) {
      print("Gold API Error: $e");
      setState(() => isLoadingGold = false);
    }
  }

  Future<void> getOwnerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      ownerName = doc.data()?['name'] ?? "Owner";
    });
  }

  Future<void> getShopName() async {
    var doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shopId)
        .get();

    setState(() {
      shopName = doc.data()?['name'] ?? widget.shopName;
    });
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xffb8610b);

    final pages = [
      homeBody(),
      widget.shopId.isEmpty
          ? const Center(child: Text("No shop yet"))
          : OrderPage(shopId: widget.shopId),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      // 🔥 MENU LEFT RESTORED
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: mainColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.store, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    shopName,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            if (widget.shopId.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text("Add Product"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminPage(
                        shopId: widget.shopId,
                        shopName: shopName,
                      ),
                    ),
                  );
                },
              ),

            if (widget.shopId.isEmpty)
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text("Create Shop"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddShopPage(
                        adminId: FirebaseAuth.instance.currentUser!.uid,
                      ),
                    ),
                  );
                },
              ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SplashPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        title: Text(shopName,
            style: const TextStyle(color: Colors.black)),
      ),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: mainColor,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget homeBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Welcome $ownerName 👑",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xffa68f45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("💰 Gold Prices Today",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  Text("24K | ${gold24K.toStringAsFixed(2)} OMR",
                      style: const TextStyle(color: Colors.white)),
                  Text("22K | ${gold22K.toStringAsFixed(2)} OMR",
                      style: const TextStyle(color: Colors.white)),
                  Text("21K | ${gold21K.toStringAsFixed(2)} OMR",
                      style: const TextStyle(color: Colors.white)),
                  Text("18K | ${gold18K.toStringAsFixed(2)} OMR",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "📈 Live Gold Chart (All Karats)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              height: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: (isLoadingGold && gold24History.isEmpty)
                  ? const Center(child: Text("Loading...", style: TextStyle(color: Colors.white)))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int i = value.toInt();
                                if (i < 0 || i >= daysHistory.length) {
                                  return const Text("");
                                }
                                return Text(
                                  daysHistory[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              gold24History.length,
                              (i) => FlSpot(i.toDouble(), gold24History[i]),
                            ),
                            isCurved: true,
                            color: Colors.amber,
                            barWidth: 3,
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              gold22History.length,
                              (i) => FlSpot(i.toDouble(), gold22History[i]),
                            ),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              gold21History.length,
                              (i) => FlSpot(i.toDouble(), gold21History[i]),
                            ),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 2,
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              gold18History.length,
                              (i) => FlSpot(i.toDouble(), gold18History[i]),
                            ),
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 2,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}