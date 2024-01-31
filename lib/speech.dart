import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:avatar_glow/avatar_glow.dart';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

const BG_COLOR = Color(0xff2C2C2C);
const TEXT_COLOR = Color(0xffFEFDFC);

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  SpeechToText speechToText = SpeechToText();
  var text = "";
  var isListening = false;
  var available = false;

  void resetText() {
    setState(() {
      text = "";
    });
  }

  Future<String> sendText(String message) async {
    var result;
    final response = await http.post(
      Uri.parse(
          "https://gdctbbtiul.execute-api.ap-northeast-1.amazonaws.com/prod/api"),
      headers: <String, String>{"Content-Type": "application/json"},
      body: json.encode({"message": message}),
    );
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      var data = jsonDecode(response.body);
      print(data);
      result = data;
    } else {
      // handle error
      print(response.statusCode);
      print(response.body);
      result = response.body;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: AvatarGlow(
        endRadius: 75.0,
        animate: isListening,
        duration: const Duration(milliseconds: 2000),
        glowColor: BG_COLOR,
        repeatPauseDuration: const Duration(milliseconds: 100),
        showTwoGlows: true,
        child: GestureDetector(
          onTap: () async {
            if (!isListening) {
              isListening = true;
              available = await speechToText.initialize();
              if (available) {
                setState(() {
                  speechToText.listen(
                    onResult: (result) {
                      setState(() {
                        text = result.recognizedWords;
                      });
                    },
                    localeId: 'ja_JP',
                  );
                });
              }
            } else {
              isListening = false;
              speechToText.stop();
            }
          },
          child: CircleAvatar(
            backgroundColor: BG_COLOR,
            radius: 35,
            child: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: BG_COLOR,
        title: const Text(
          '俺のふんぽう←なぜか変換できない',
          style: TextStyle(fontWeight: FontWeight.w600, color: TEXT_COLOR),
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.only(bottom: 150),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    var sendText = "";
    Timer.periodic(Duration(seconds: 180), (timer) async {
      print("text.length: ${text.length}");
      if (text.length < 100) {
        print("return");
        return;
      }
      sendText = text;
      if (isListening) {
        await speechToText.cancel();
        setState(() {
          resetText();
          isListening = false;
        });

        await Future.delayed(Duration(seconds: 1));
        available = await speechToText.initialize();
        if (available) {
          await speechToText
              .listen(
                onResult: (result) {
                  setState(() {
                    print("recognized word: ${result.recognizedWords}");
                    text = result.recognizedWords;
                  });
                },
                localeId: 'ja_JP',
              )
              .onError((error, stackTrace) => print(error));
        }
        isListening = true;

        int splitIndex = 3000;

        String input;
        if (splitIndex <= text.length) {
          input = sendText.substring(0, splitIndex);
        } else {
          input = sendText;
        }
        print("sendText: $input");
        final response = await http.post(
          Uri.parse(
              "/prod/api"),
          headers: <String, String>{"Content-Type": "application/json"},
          body: json.encode({"message": input}),
        );
        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, parse the JSON.
          var data = jsonDecode(response.body);
          print(data);
        } else {
          // handle error
          print(response.statusCode);
          print(response.body);
        }
      }
    });
  }
}
