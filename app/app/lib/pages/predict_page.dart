import 'dart:convert';
import 'package:app/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({Key? key}) : super(key: key);

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  String output = "Please click on Predict ASC or SED button to make the prediction";
  bool isLoading = false;

  Future<void> predictSed() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse("https://f576-2409-408c-280a-4f2b-6dd7-f554-a0d8-20a1.ngrok-free.app/predict_sed");
    final response = await http.get(url);
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    setState(() {
      output = "Predicted SED as " + decoded['test'];
      isLoading = false;
    });
    if(decoded['test'] == 'siren'){
      Vibration.vibrate(
        pattern: [500, 1000, 500, 2000, 500, 3000],intensities: [0, 64, 0, 128, 0, 255],
      );
    }
  }

  Future<void> predictAsc() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse("https://f576-2409-408c-280a-4f2b-6dd7-f554-a0d8-20a1.ngrok-free.app/predict_asc");
    final response = await http.get(url);
    final decoded = json.decode(response.body) as Map<String, dynamic>;
    setState(() {
      output = "Predicted ASC as " + decoded['test.wav'];
      isLoading = false;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  output,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: predictAsc,
              child: const Text("Predict ASC"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: predictSed,
              child: const Text("Predict SED"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              child: const Text("Go back to home page"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
