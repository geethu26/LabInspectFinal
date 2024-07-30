import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:lab_inspect/globals.dart';
// import 'package:ftoast/ftoast.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  List designations = ['Lab Assistant', 'HOD', 'Faculty', 'Admin', 'Authority  '];
  List departments = ['CMPN','IT','EXTC','ELEC','MECH','FE','STAFF'];
  String? choose;
  String? dept;
  TextEditingController nameController = TextEditingController();
  TextEditingController pidController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confpasswordController = TextEditingController();
  bool passwordMatch = false;

  Future<void> _signup(Map<String,String> data) async {
    String apiUrl = '$url/api/signup';
    try {
      var response = await http.post (
        Uri.parse(apiUrl),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      if(response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'Data sent!',
          toastLength: Toast.LENGTH_LONG,
        );
        if (!context.mounted) return;
        await Navigator.pushNamed(context, 'login');
      }
      else {
        Fluttertoast.showToast(
          msg: 'Failed! Status Code: ${response.statusCode}',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
    catch(e) {
      // print(e);
      Fluttertoast.showToast(
        msg: 'Error sending data: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _onButtonPressed() {
    if(passwordMatch) {
      if(dept != 'Select Department' && choose != 'Select Designation') {
        String name = nameController.text;
        String pid = pidController.text;
        String email = emailController.text;
        String password = passwordController.text;
        String designation = choose!;
        String department = dept!;
        Map<String,String> data = {
          'name': name,
          'pid': pid,
          'email': email,
          'password': password,
          'designation': designation,
          'department': department,
        };
        _signup(data);
      }
    }
    else {
      Fluttertoast.showToast(
        msg: 'Passwords dont match.',
        toastLength: Toast.LENGTH_SHORT,
      );
    }
    // FToast.toast(
    //   context,
    //   duration: 800,
    //   msg: 'IM a toast',
    //   msgStyle: const TextStyle(color: Colors.white),
    //   padding: const EdgeInsets.symmetric(vertical: 80),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/loginbg.jpg'), fit: BoxFit.cover)
        ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.3, vertical: MediaQuery.of(context).size.height*0),
                child: const Text('SIGN UP', style: TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.bold),),
              ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.1, vertical: MediaQuery.of(context).size.width*0.15),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 18),
                          hintText: 'Enter Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: pidController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 18),
                          hintText: 'Enter PID',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 18),
                          hintText: 'Enter Email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: passwordController,
                        style: const TextStyle(fontSize: 18),
                        obscureText: true,
                        onChanged: (password) {
                          String confpassword = confpasswordController.text;
                          setState(() {
                            passwordMatch = password == confpassword;
                          });
                        },
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 18),
                          hintText: 'Enter Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      TextField(
                        controller: confpasswordController,
                        style: const TextStyle(fontSize: 18),
                        obscureText: true,
                        onChanged: (confpassword) {
                          String password = passwordController.text;
                          setState(() {
                            passwordMatch = password == confpassword;
                          });
                        },
                        decoration: InputDecoration(
                          hintStyle: const TextStyle(fontSize: 18),
                          hintText: 'Confirm Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(width: 5.0)),
                          errorText: passwordMatch?null:'Passwords do not match.'
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.025, vertical: MediaQuery.of(context).size.width*0.015),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: const Color.fromARGB(255, 129, 128, 128)),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: DropdownButton(
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined,),
                          style: const TextStyle(color: Colors.black, fontSize: 18,),
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(10),
                          value: choose,
                          onChanged: (String? newValue) {
                            setState(() {
                              choose = newValue!;
                          });
                        },
                        hint: const Text('Select Designation'),
                        items: ['Select Designation', ...designations].map((valueItem) {
                          return DropdownMenuItem<String>(
                            value: valueItem,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(valueItem, textAlign: TextAlign.left,),
                            ) 
                          );
                        }).toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width*0.025, vertical: MediaQuery.of(context).size.width*0.015),
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: const Color.fromARGB(255, 129, 128, 128)),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: DropdownButton(
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined,),
                          style: const TextStyle(color: Colors.black, fontSize: 18,),
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(10),
                          value: dept,
                          onChanged: (String? newValue) {
                            setState(() {
                              dept = newValue!;
                          });
                        },
                        hint: const Text('Select Department'),
                        items: ['Select Department', ...departments].map((valueItem) {
                          return DropdownMenuItem<String>(
                            value: valueItem,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(valueItem, textAlign: TextAlign.left,),
                            ) 
                          );
                        }).toList(),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
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