import 'dart:async';
import 'package:flutter/material.dart';
import 'package:midtter/midtter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isMakePayment = false;
  final midtter = Midtter();
  @override
  void initState() {
    super.initState();
    midtter.init("SB-Mid-client-f82DWb-NJCZV_iPJ", "http://api-dev.foodspot.co.id/v1/");
    midtter.setFinishCallback(_callback);
  }

  _makePayment() {
    setState(() {
      isMakePayment = true;
    });
    midtter
        .makePayment(
          MidtransTransaction(
              "order_id1234567890",
              7500,
              MidtransCustomer(
                  "Apin", "Prastya", "apin.klas@gmail.com", "085235419949"),
              [
                MidtransItem(
                  "5c18ea1256f67560cb6a00cdde3c3c7a81026c29",
                  7500,
                  1,
                  "USB FlashDisk",
                )
              ],
              skipCustomer: true,
              customField1: "ANYCUSTOMFIELD",
              paymentMethod: "cc"),
        )
        .catchError((err) => print("ERROR $err"));
  }

  Future<void> _callback(TransactionFinished finished) async {
    setState(() {
      isMakePayment = false;
    });
    return Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Center(
          child: isMakePayment
              ? CircularProgressIndicator()
              : RaisedButton(
                  child: Text("Make Payment"),
                  onPressed: () => _makePayment(),
                ),
        ),
      ),
    );
  }
}
