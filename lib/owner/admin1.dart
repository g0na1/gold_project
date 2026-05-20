
import 'package:act3/owner/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AdminRegisterPage.dart';


class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signInAdmin() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (!isEmailValid(email)) {
      showMessage("Please enter a valid email");
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user == null) {
        showMessage("User not found");
        return;
      }

      // 🔍 التحقق من أنه أدمن
      final adminDoc = await FirebaseFirestore.instance
          .collection('admin')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) {
        showMessage("Not an admin account");
        return;
      }

      // 🔥 التحقق من التفعيل
      bool isActive = adminDoc['isActive'] ?? false;

      if (!isActive) {
        showMessage("Your account is not approved yet ⏳");
        return;
      }

      // 🔍 جلب المتجر
      final shopQuery = await FirebaseFirestore.instance
          .collection('shops')
          .where('adminId', isEqualTo: user.uid)
          .limit(1)
          .get();

      // ✅ إذا ما عنده متجر → يدخل الهوم بدون متجر
      if (shopQuery.docs.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePageUI(
              shopId: "",
              shopName: "No Shop Yet",
            ),
          ),
        );
        return;
      }

      // ✅ عنده متجر
      final shopDoc = shopQuery.docs.first;
      final shopId = shopDoc.id;
      final shopName = shopDoc['name'] ?? "My Shop";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePageUI(
            shopId: shopId,
            shopName: shopName,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Login Failed");
    } catch (e) {
      showMessage("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffFFF8E7), // ذهبي فاتح جداً
              Color.fromARGB(255, 211, 175, 86), // ذهبي فاتح
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          size: 70, color:  Color.fromARGB(255, 146, 110, 12),),
                      const SizedBox(height: 15),

                      const Text(
                        "gold manager",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color:  Color.fromARGB(255, 146, 110, 12),
                        ),
                      ),

                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon:
                              const Icon(Icons.email,  color: Color.fromARGB(255, 146, 110, 12),),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon:
                              const Icon(Icons.lock,  color: Color.fromARGB(255, 146, 110, 12)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signInAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  Color.fromARGB(255, 146, 110, 12),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Sign In",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No gold manager account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminRegisterPage()),
                              );
                            },
                            child: const Text(
                              "Register here",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

