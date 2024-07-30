import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import "package:http/http.dart" as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lab_inspect/globals.dart';
import 'package:lab_inspect/session.dart';

class QRScan extends StatefulWidget {
  const QRScan({super.key});

  @override
  State<QRScan> createState() => _QRScanState();
}

class ScanArguments {
  final int index;
  final Function(int) onDelete;
  final Map<String,String> data;
  final String date;
  ScanArguments(this.index, this.onDelete, this.data, this.date);
}

class QrCodeData {
  final String details;
  bool status;
  String comments;
  bool isDuplicate;
  QrCodeData({
    required this.details,
    required this.status,
    required this.comments,
    required this.isDuplicate
  });
}

class _QRScanState extends State<QRScan> {

  List<QrCodeData> qrCodes = [];

  @override
  void initState() {
    super.initState();
    fetchDataFromBackend();
  }

  bool hasDuplicates(List<QrCodeData> qrCodes, String details) {
    return qrCodes.any((code) => code.details == details);
  }

  Future<void> fetchDataFromBackend() async {
    var apiUrl = '$url/api/gettempscanpost';
    String? pid = await SessionManager.getPid();
    if(!context.mounted) return;
    final ScanArguments args = ModalRoute.of(context)!.settings.arguments as ScanArguments;
    Map<String,dynamic> senddata = {
      'pid': pid,
      'labnumber': args.data['labnumber'],
      'date': args.date,
    };
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(senddata),
      );
      if(response.statusCode == 200){
        final List<dynamic> data = json.decode(response.body)['documents'];
        // print(data);
        setState(() {
          qrCodes = data.map(
            (item) => QrCodeData(
              details: item['details'],
              status: item['status'],
              comments: item['comments'],
              isDuplicate: hasDuplicates(qrCodes, item['details']),
            )).toList();
        });
      }
      else {
        Fluttertoast.showToast(
        msg: 'Error! ${response.statusCode}',
        toastLength: Toast.LENGTH_LONG,
      );
      }
    }
    catch(e){
      Fluttertoast.showToast(
        msg: 'Error!',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _deleteitem() async {
    final ScanArguments args = ModalRoute.of(context)!.settings.arguments as ScanArguments;
    args.onDelete(args.index); // Call the onDelete function to delete the item
    var apiUrl = '$url/api/delscansession';
    try{
      var response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(args.data)
      ).timeout(const Duration(seconds: 10));
      if(response.statusCode == 200){
        Fluttertoast.showToast(
            msg: 'Scan session Deleted!',
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
        msg: 'Error deleting data: $e',
        toastLength: Toast.LENGTH_LONG,
      );
    }
    if(!context.mounted) return;
    Navigator.pop(context);
  }

  void _deleteEntry(int index) {
    setState(() {
      qrCodes.removeAt(index);
    });
  }

  void scanQRCode() async {
    try {
      final qrcode = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.QR);
      if (!context.mounted) return;
      setState(() {
        bool isDuplicate = qrCodes.any((element) => element.details == qrcode);
        qrCodes.add(QrCodeData(details: qrcode, status: false, comments: '', isDuplicate: isDuplicate));
      });
    } on PlatformException {
      Fluttertoast.showToast(
        msg: "Failed to scan QR.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _sendToBackend() async {
    String? pid = await SessionManager.getPid();
    if(!context.mounted) return;
    final ScanArguments args = ModalRoute.of(context)!.settings.arguments as ScanArguments;
    try {
      List<Map<String,dynamic>> data = qrCodes.map((qrCode) {
        return {
          'details': qrCode.details,
          'status': qrCode.status,
          'comments': qrCode.comments,
        };
      }).toList();
      var apiUrl = '$url/api/tempscanpost';
      var senddata = {
          'pid': pid,
          'labnumber': args.data['labnumber'],
          'date': args.data['date'],
          'data': data,
        };
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(senddata),
      );
      
      if(response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'Data Uploaded!',
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
  // var result = 'QR Result';

  int countDuplicates(int index) {
    // Get the details of the entry at the specified index
    String detailsToMatch = qrCodes[index].details;

    // Count the number of entries in qrCodes with the same details
    int duplicateCount = qrCodes.where((entry) => entry.details == detailsToMatch).length;

    return duplicateCount;
  }

  void _showCommentInputDialog(BuildContext context, QrCodeData qrCode) {
    TextEditingController commentController = TextEditingController();
    commentController.text = qrCode.comments;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comments'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(labelText: 'Comments'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
            }, 
            child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  qrCode.comments = commentController.text;
                });
                Navigator.of(context).pop();
              }, 
              child: const Text('Save'),
              )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendToBackend();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
               _deleteitem();
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: scanQRCode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMaxHeight: double.infinity,
            columns: const [
              DataColumn(
                label: SizedBox(width: 21, child: Center(child: Text('Sr\nNo.'))),
              ),
              DataColumn(
                label: SizedBox(width: 120, child: Center(child: Text('Details'))),
              ),
              DataColumn(
                label: SizedBox(width: 50, child: Center(child: Text('Status'))),
              ),
              DataColumn(
                label: SizedBox(width: 170, child: Center(child: Text('Comments'))),
              ),
              DataColumn(
                label: SizedBox(width: 45, child: Center(child: Text('Action'))),
              ),
            ],
            rows: qrCodes.asMap().entries.map(
              (entry) => DataRow(
                
                color: MaterialStateColor.resolveWith((states) {
                  int duplicateCount = countDuplicates(entry.key); // Get the count of duplicates for the entry
                  return (entry.value.isDuplicate && duplicateCount > 1) ? Colors.red[100]! : Colors.transparent;
                  // return entry.value.isDuplicate ? Colors.red[100]! : Colors.transparent;
                }),
                cells: [
                  DataCell(Text((entry.key + 1).toString())),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0), // Adjust the vertical padding as needed
                      child: Center(
                        child: Text(entry.value.details),
                      ),
                    ),
                  ),
                  DataCell(Checkbox(
                    value: entry.value.status,
                    onChanged: (newValue) {
                      setState(() {
                        qrCodes[entry.key].status = newValue ?? false;
                      });
                    },
                  )),
                  DataCell(
                    GestureDetector(
                      onTap: () {
                        _showCommentInputDialog(context, qrCodes[entry.key]);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          style: const TextStyle(fontSize: 16),
                          qrCodes[entry.key].comments,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteEntry(entry.key);
                    },
                  )),
                ],
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}