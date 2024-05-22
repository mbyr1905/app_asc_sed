import 'dart:convert';
import 'dart:io';
import 'package:app/pages/predict_audio_recording_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class RecordAudio extends StatefulWidget {
  const RecordAudio({Key? key});

  @override
  State<RecordAudio> createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  late Record audioRecorder;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecorder = Record();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    audioRecorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        await audioRecorder.start();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecorder.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
      print('audio saved at this path $audioPath');
      await renameAndChangeFormat();
    } catch (e) {
      print('error stopping recording: $e');
    }
  }

  Future<void> renameAndChangeFormat() async {
    try {
      File file = File(audioPath);
      String directory = file.parent.path;
      String newPath = '$directory/test.wav';
      await file.rename(newPath);
      setState(() {
        audioPath = newPath;
      });
      print('audio converted and renamed to $audioPath');
    } catch (e) {
      print('error renaming and changing format: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print('error playing recording: $e');
    }
  }

  Future<void> pickAndSave() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;
      final file = File(result.files.first.path!);

      final appDir = await getTemporaryDirectory();
      final newPath = '${appDir.path}/test.wav';

      await file.copy(newPath);

      setState(() {
        audioPath = newPath;
      });
      print('audio saved in cache with name test.wav');
    } catch (e) {
      print('error picking and saving: $e');
    }
  }

  Future<void> uploadAudio() async {
    try {
      if (!File(audioPath).existsSync()) {
        print('File does not exist');
        return;
      }

      final url = Uri.parse(
          "https://f576-2409-408c-280a-4f2b-6dd7-f554-a0d8-20a1.ngrok-free.app/upload_audio");

      final request = http.MultipartRequest("POST", url);
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        filename: 'test.wav',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        print('Upload success: ${resJson['message']}');
      } else {
        print('Upload failed: ${response.reasonPhrase}');
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PredictASCPage(),
        ),
      );
    } catch (e) {
      print('error uploading audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Recording and Playing"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isRecording
                ? const Text(
                    'Recording in Progress',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                    ),
                  )
                : Container(),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: isRecording
                  ? const Text('Stop Recording')
                  : const Text('Start Recording'),
            ),
            const SizedBox(height: 25),
            if (!isRecording && audioPath.isNotEmpty)
              ElevatedButton(
                onPressed: playRecording,
                child: const Text('Play Recording'),
              ),
            const SizedBox(height: 25),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: audioPath.isNotEmpty ? uploadAudio : null,
              child: const Text('Upload Recorded Audio'),
            ),
          ],
        ),
      ),
    );
  }
}
