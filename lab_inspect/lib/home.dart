import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lab_inspect/scan.dart';
import 'package:lab_inspect/session.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:lab_inspect/globals.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> historyItems = [];
  TextEditingController labnumberController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _fetchDocs();
  }

  void deleteItem(int index) {
    setState(() {
      if (index >= 0 && index < historyItems.length) {
        historyItems.removeAt(index);
      }
    });
  }

  Future<void> _showlabnumberDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Lab Number'),
          content: TextField(
            controller: labnumberController,
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                String? pid = await SessionManager.getPid();
                String labnumber = labnumberController.text;
                if(labnumber.isNotEmpty){
                  String currenttime = DateFormat('HH:mm:ss').format(DateTime.now());
                  String currentdate = DateFormat('dd/MM/yyyy').format(DateTime.now());
                  setState(() {
                    historyItems.add({'labnumber': labnumber, 'time': currenttime, 'date': currentdate});
                  });
                  _senddata(labnumber, currentdate, currenttime, pid);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  labnumberController.clear();
                }
              },
            ),
          ],
        );
      }
    );
  }

  Future<void> _senddata(String labnumber, String date, String time, String? pid) async {
    var apiUrl = '$url/api/scansession';
    Map<String,String> data = {
      'labnumber': labnumber,
      'date': date,
      'time': time,
      'pid': pid??'',
    };
    try{
      var response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data)
      ).timeout(const Duration(seconds: 10));
      if(response.statusCode == 201){
        Fluttertoast.showToast(
          msg: 'Scan session Created!',
          toastLength: Toast.LENGTH_LONG,
        );
      }
      else {
        Fluttertoast.showToast(
          msg: 'Failed! Status Code: ${response.statusCode}',
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
    catch(e){
      Fluttertoast.showToast(
        msg: 'Error sending data: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<List<Map<String,dynamic>>> fetchDocuments(String? pid) async {
    var apiUrl = '$url/api/getdocs';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({'pid': pid}),
      );
      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['documents'];
        return data.cast<Map<String,dynamic>>();
      }
      else{
        return historyItems;
      }
    }
    catch(e){
      Fluttertoast.showToast(
        msg: 'Error!',
        toastLength: Toast.LENGTH_LONG,
      );
      return historyItems;
    }
  }

  Future<void> _fetchDocs() async {
    String? pid = await SessionManager.getPid();
    if(pid!=null){
      List<Map<String,dynamic>> documents = await fetchDocuments(pid);
      setState(() {
        historyItems = documents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/loginbg.jpg'), fit: BoxFit.cover)
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showlabnumberDialog();
              },
            ),
            PopupMenuButton(
              onSelected: (value) async {
                if (value == 'logout') {
                  await SessionManager.setUserLoggedIn(false,null);
                  if (!context.mounted) return;
                  await Navigator.pushNamed(context, 'login');
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String> (
                  value: 'logout',
                  child: Text('Logout'),
                )
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 3.5,
              mainAxisSpacing: 10,
            ),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              return ElevatedButton(
                onPressed: () async {
                  String? pid = await SessionManager.getPid();
                  String date = historyItems[index]["date"];
                  Map<String,String> data = {
                    'labnumber': '${historyItems[index]["labnumber"]}',
                    'date': '${historyItems[index]["date"]}',
                    'time': '${historyItems[index]["time"]}',
                    'pid': pid??'',
                  };
                  if(!context.mounted) return;
                  Navigator.pushNamed(context, 'scan', arguments: ScanArguments(index, deleteItem, data, date),);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lab Number: ${historyItems[index]["labnumber"]}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Session Date: ${historyItems[index]["date"]}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Session Time: ${historyItems[index]["time"]}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/*  onPressed: () async {
            // Set the user login status to false and navigate to the login screen
            await SessionManager.setUserLoggedIn(false);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
          child: Text('Logout'), */