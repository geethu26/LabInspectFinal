import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lab_inspect/login.dart';
import 'package:lab_inspect/signup.dart';
import 'package:lab_inspect/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lab_inspect/scan.dart';
import 'package:lab_inspect/globals.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var connectivityResult = await (Connectivity().checkConnectivity());
  if(connectivityResult == ConnectivityResult.none) {
    showtoast("No Internet Connection.");
  }
  /* SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  //initialRoute: 'home',
  initialRoute: isLoggedIn ? 'home' : 'login',
  routes: {
      'login': (context) => const Login(),
      'signup': (context) => const Signup(),
      'home': (context) => const Home(),
      'scan': (context) => const QRScan(),
    },
  ));
} */
  try {
    var response = await http.post(
      Uri.parse('$url/api/test'),
      body: {},
    );
    if (response.statusCode == 200) {
      showtoast("Connected!");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      //initialRoute: 'home',
      initialRoute: isLoggedIn ? 'home' : 'login',
      routes: {
          'login': (context) => const Login(),
          'signup': (context) => const Signup(),
          'home': (context) => const Home(),
          'scan': (context) => const QRScan(),
        },
      ));
    }
    else {
      showtoast("Failed to connect to server.");
    }
  }
  catch(e) {
    showtoast("Failed to connect.");
  }
}

void showtoast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
  );
}