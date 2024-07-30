import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lab_inspect/session.dart';
import "package:lab_inspect/globals.dart";

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  TextEditingController pidController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _login(Map<String,String> data, String pid) async {
    String apiUrl = '$url/api/login';
     try {
      var response = await http.post (
        Uri.parse(apiUrl),
        // headers: {'Content-type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      var jsonresp = jsonDecode(response.body);
      var message = jsonresp['message'];
      if(response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Logged In!',
          toastLength: Toast.LENGTH_LONG,
        );
        await SessionManager.setUserLoggedIn(true, pid);
        if (!context.mounted) return;
        await Navigator.pushNamed(context, 'home');
        // navigatorKey.currentState?.pushNamed('home');
      }
      else {
        // ('$message');
        Fluttertoast.showToast(
          msg: "Failed! $message",
          toastLength: Toast.LENGTH_LONG,
        );
        // print(response.body);
      }
    }
    catch(e) {
      // print(e);
      Fluttertoast.showToast(
        msg: 'Error: Timeout error!',
        toastLength: Toast.LENGTH_LONG,
      );
      // print(e);
    }
  }

  void _onButtonPressed() {
    String pid = pidController.text;
    String password = passwordController.text;
    if (pid.isNotEmpty && password.isNotEmpty) {
      Map<String,String> data = {
      'pid': pid,
      'password': password,
    };
    _login(data, pid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/loginbg.jpg'), fit: BoxFit.cover)
        ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.36, vertical: MediaQuery.of(context).size.height*0.25),
                child: const Text('LOGIN', style: TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold),),
              ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.1, vertical: MediaQuery.of(context).size.width*0.7),
                  child: Column(
                    children: [
                      TextField(
                        controller: pidController,
                        decoration: InputDecoration(
                          hintText: 'Enter PID',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // const Text('Sign Up', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color.fromARGB(255, 64, 63, 63),
                            child: IconButton(color:Colors.white, onPressed: _onButtonPressed, icon: const Icon(Icons.arrow_forward)),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 60,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: () {Navigator.pushNamed(context, 'signup');}, child: const Text('Sign Up', style: TextStyle(decoration: TextDecoration.underline, fontSize: 20, color: Colors.black),)),
                          TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(decoration: TextDecoration.underline, fontSize: 20, color: Colors.black),))                        
                        ],
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}