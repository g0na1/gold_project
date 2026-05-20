


import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'splash_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCYNoFkrc_tRAILwzQKK4KgCxPxPfgi3s8",
  authDomain: "course-project-c32b5.firebaseapp.com",
  projectId: "course-project-c32b5",
  storageBucket: "course-project-c32b5.firebasestorage.app",
  messagingSenderId: "247820900713",
  appId: "1:247820900713:web:cea81cfd8ea13f8eabc5f8",
  measurementId: "G-YG5VMX9Q19"
     )
  );

  runApp(GoldApp());
}

class GoldApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Gold Shopping",
      theme: ThemeData(primarySwatch: Colors.amber),
      home: SplashPage(),
    );
  }
}