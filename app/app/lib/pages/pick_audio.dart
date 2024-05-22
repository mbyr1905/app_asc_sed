import 'dart:convert';
import 'dart:io';

import 'package:app/pages/predict_page.dart';

import 'homepage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;

class PickAudio extends StatefulWidget {
  const PickAudio({Key? key}) : super(key: key);

  @override
  State<PickAudio> createState() => _PickAudioState();
}

class _PickAudioState extends State<PickAudio> {
  FlutterSoundPlayer? _player = FlutterSoundPlayer();

  File? selectedAudio;
  String? message = "";

  Future<void> uploadAudio() async {
    if (selectedAudio == null) {
      setState(() {
        message = "Please select audio to upload";
      });
      return;
    }

    final url = Uri.parse(
        "https://f576-2409-408c-280a-4f2b-6dd7-f554-a0d8-20a1.ngrok-free.app/upload_audio");

    final request = http.MultipartRequest("POST", url);

    request.files.add(await http.MultipartFile.fromPath(
        'audio', selectedAudio!.path,
        filename: selectedAudio!.path.split('/').last));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final resJson = jsonDecode(response.body);
      setState(() {
        message = resJson['message'];
      });
    } else {
      setState(() {
        message = "Failed to upload audio";
      });
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PredictPage(),
      ),
    );
  }

  Future<void> getAudio() async {
    final pickedAudio = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav']);

    if (pickedAudio != null) {
      setState(() {
        selectedAudio = File(pickedAudio.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Pick Audio Page'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            selectedAudio == null
                ? const Text(
                    "Please select audio to upload",
                    style: TextStyle(fontSize: 18),
                  )
                : Text(
                    selectedAudio!.path,
                    style: TextStyle(fontSize: 18),
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: uploadAudio,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Upload"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message ?? "",
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: getAudio,
              child: const Text("Select Audio"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: getAudio,
        child: const Icon(Icons.mic),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
