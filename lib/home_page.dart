import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import 'all_shops_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'ShopDetailsPage.dart';
import 'myorder.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _topController =
      PageController(viewportFraction: 0.85);

  Timer? _timer;
  Timer? goldTimer;

  static const double usdToOmr = 0.384;

  double gold24K = 58.40;
  double gold22K = 53.61;
  double gold21K = 50.31;
  double gold18K = 43.12;

  List<double> gold24History = [];
  List<String> daysHistory = [];
  List<double> gold22History = [];
  List<double> gold21History = [];
  List<double> gold18History = [];

  final List<String> topImages = [
    "https://images.unsplash.com/photo-1617038220319-276d3cfab638",
    "https://images.unsplash.com/photo-1605100804763-247f67b3557e",
    "https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f",
  ];

  String searchQuery = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_topController.hasClients) {
        int next = _topController.page!.round() + 1;

        if (next >= topImages.length) {
          next = 0;
        }

        _topController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    fetchGoldPrice();

    goldTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        fetchGoldPrice();
      },
    );
  }

  Future<void> fetchGoldPrice() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.gold-api.com/price/XAU"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        double pricePerOunce = data['price'];
        double pricePerGram = pricePerOunce / 31.1035;

        setState(() {
          gold24K = pricePerGram;
          gold22K = pricePerGram * 0.916;
          gold21K = pricePerGram * 0.875;
          gold18K = pricePerGram * 0.75;

          gold24History.add(gold24K * usdToOmr);
          gold22History.add(gold22K * usdToOmr);
          gold21History.add(gold21K * usdToOmr);
          gold18History.add(gold18K * usdToOmr);
daysHistory.add(
  "${DateTime.now().day}/${DateTime.now().month}",
);

          // نحافظ فقط على آخر 30 نقطة
          if (gold24History.length > 30) {
            gold24History.removeAt(0);
            gold22History.removeAt(0);
            gold21History.removeAt(0);
            gold18History.removeAt(0);
            daysHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      print("Gold API error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    goldTimer?.cancel();
    _topController.dispose();
    super.dispose();
  }

  void onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xffb8610b),
              ),
              child: Text(
                "Welcome ${widget.userName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),

            // 🔥 MY ORDERS
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffb8610b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffb8610b),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text(
                    "My Orders",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xffb8610b),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xffb8610b),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyOrdersPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onNavTap,
        selectedItemColor: const Color(0xffb8610b),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: "Stores",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homeContent(),

          const AllShopsPage(),

          CartPage(
            onBack: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),

          ProfilePage(userName: widget.userName),
        ],
      ),
    );
  }

  Widget _homeContent() {
    double gold24K_OMR = gold24K * usdToOmr;
    double gold22K_OMR = gold22K * usdToOmr;
    double gold21K_OMR = gold21K * usdToOmr;
    double gold18K_OMR = gold18K * usdToOmr;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔝 TOP BAR
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),

                  Text(
                    "Hey ${widget.userName} 👋",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Icon(Icons.notifications_none),
                ],
              ),

              const SizedBox(height: 10),

              // 🔍 SEARCH
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search stores...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 💰 GOLD PRICES
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 166, 143, 69),
                      Color.fromARGB(255, 166, 143, 69),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "💰 Gold Prices Today",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "24K | ${gold24K_OMR.toStringAsFixed(2)} OMR",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      "22K | ${gold22K_OMR.toStringAsFixed(2)} OMR",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      "21K | ${gold21K_OMR.toStringAsFixed(2)} OMR",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      "18K | ${gold18K_OMR.toStringAsFixed(2)} OMR",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // 📈 CHART
              Container(
                height: 280,
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: gold24History.isEmpty
                    ? const Center(
                        child: Text(
                          "Loading...",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX:
                              (gold24History.length - 1)
                                  .toDouble(),

                          minY: [
                                ...gold24History,
                                ...gold22History,
                                ...gold21History,
                                ...gold18History,
                              ].reduce(
                                    (a, b) =>
                                        a < b ? a : b,
                                  ) -
                              1,

                          maxY: [
                                ...gold24History,
                                ...gold22History,
                                ...gold21History,
                                ...gold18History,
                              ].reduce(
                                    (a, b) =>
                                        a > b ? a : b,
                                  ) +
                              1,

                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 1,
                            verticalInterval: 1,
                          ),

                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Colors.white24,
                            ),
                          ),

                          titlesData: FlTitlesData(
                            topTitles:
                                const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),

                            rightTitles:
                                const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                              ),
                            ),

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 42,
                                getTitlesWidget:
                                    (value, meta) {
                                  return Text(
                                    value
                                        .toStringAsFixed(
                                            0),
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),

                            bottomTitles:
                                AxisTitles(
                              sideTitles:
                                  SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget:
                                    (value, meta) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      top: 8,
                                    ),
                                  child: Text(
  value.toInt() < daysHistory.length
      ? daysHistory[value.toInt()]
      : "",
  style: const TextStyle(
    color: Colors.white,
    fontSize: 9,
  ),
),
                                  );
                                },
                              ),
                            ),
                          ),

                          lineBarsData: [

                            // 24K
                            LineChartBarData(
                              spots: List.generate(
                                gold24History.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  gold24History[i],
                                ),
                              ),
                              isCurved: true,
                              color: Colors.amber,
                              barWidth: 3,
                              dotData:
                                  const FlDotData(
                                show: false,
                              ),
                            ),

                            // 22K
                            LineChartBarData(
                              spots: List.generate(
                                gold22History.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  gold22History[i],
                                ),
                              ),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              dotData:
                                  const FlDotData(
                                show: false,
                              ),
                            ),

                            // 21K
                            LineChartBarData(
                              spots: List.generate(
                                gold21History.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  gold21History[i],
                                ),
                              ),
                              isCurved: true,
                              color: Colors.green,
                              barWidth: 3,
                              dotData:
                                  const FlDotData(
                                show: false,
                              ),
                            ),

                            // 18K
                            LineChartBarData(
                              spots: List.generate(
                                gold18History.length,
                                (i) => FlSpot(
                                  i.toDouble(),
                                  gold18History[i],
                                ),
                              ),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData:
                                  const FlDotData(
                                show: false,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 15),

              // 🔥 SLIDER
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _topController,
                  itemCount: topImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: Image.network(
                          topImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // 🔥 HEADER
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Gold Stores",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AllShopsPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "See More",
                      style: TextStyle(
                        color: Color(0xffb8610b),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // 🔥 STORES
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('shops')
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final docs =
                      snapshot.data!.docs.where((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final name = data['name']
                        .toString()
                        .toLowerCase();

                    return name.contains(
                      searchQuery.toLowerCase(),
                    );
                  }).toList();

                  return SizedBox(
                    height: 190,
                    child: ListView.builder(
                      scrollDirection:
                          Axis.horizontal,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {

                        final data =
                            docs[index].data()
                                as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShopDetailsPage(
                                  shopId:
                                      docs[index].id,
                                  shopName:
                                      data['name'],
                                ),
                              ),
                            );
                          },

                          child: Container(
                            width: 140,
                            margin:
                                const EdgeInsets.only(
                              right: 12,
                            ),

                            child: Card(
                              elevation: 5,

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                              ),

                              child: Column(
                                children: [

                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius
                                            .vertical(
                                      top:
                                          Radius.circular(
                                        15,
                                      ),
                                    ),

                                    child: Image.network(
                                      data['image'] ?? "",
                                      height: 110,
                                      width:
                                          double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  Padding(
                                    padding:
                                        const EdgeInsets
                                            .all(8),

                                    child: Text(
                                      data['name'] ?? "",
                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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