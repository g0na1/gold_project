
import 'package:act3/owner/admin1.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String shopName = "";
  bool isActive = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('admin')
        .doc(user.uid)
        .get();

    setState(() {
      username = doc.data()?['username'] ?? "No Name";
      email = doc.data()?['email'] ?? "No Email";
      shopName = doc.data()?['shopName'] ?? "No Shop";
      isActive = doc.data()?['isActive'] ?? false;
      isLoading = false;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xffb8610b);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),

          // 👤 Avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: mainColor,
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),

          const SizedBox(height: 15),

          // 👤 Username
          Text(
            username,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          // 📧 Email
          Text(
            email,
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 25),

          // 📦 Card Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                infoCard("Account Status",
                    isActive ? "Active ✅" : "Waiting Approval ⏳"),

                infoCard("Shop Name", shopName),

                const SizedBox(height: 20),

                // 🚪 Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.info, color: Color(0xffb8610b)),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

