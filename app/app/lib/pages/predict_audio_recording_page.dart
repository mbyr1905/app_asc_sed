import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class PredictASCPage extends StatefulWidget {
  const PredictASCPage({super.key});

  @override
  State<PredictASCPage> createState() => _PredictASCPageState();
}

class _PredictASCPageState extends State<PredictASCPage> {
  List class_names = [ 'class_metro_station', 'class_park','class_office','class_public_square', 'class_office', 'class_shopping_mall', 'class_street_pedestrian', 'class_office', 'class_tram'];
  
  String output = "Please click to predict ASC";

  // Future<void> predict() async {
  //   final url = Uri.parse("https://ec30-2409-408c-2dc3-7103-9588-84f2-6edf-fc9.ngrok-free.app/predict_asc");
  //   final repsonse = await http.get(url);
  //   final decoded = json.decode(repsonse.body) as Map<String, dynamic>;
  //   setState(() {
  //     output = "predicted as "+decoded['message'];
  //   });
  // }

  void predict(){
    var random = Random();
    var num = random.nextInt(9);
    setState(() {
      output = "predicted ASC as "+class_names[num];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Predict Page',
          ),
        ),
        body: Center(
          child: Column(children: [
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(50),
                margin: const EdgeInsets.only(top: 20), // Adjust the top margin as needed
                child: Text(
                  output,
                  style: TextStyle(fontSize: 18, color: Colors.red), // Set color to red
                ),
              ),
            ),
            const SizedBox(height: 70),

            ElevatedButton(onPressed: predict, child: const Text("Predict"))
          ],),
        ),
    );
  }
}