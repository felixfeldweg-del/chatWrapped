import 'dart:io';

import 'package:chatstats/Stats.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileChooser extends StatelessWidget {
  const FileChooser({super.key});

  void pickFile(context) async{
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if(result == null) return;

    final file = result.files.first;
    if(file.extension != "txt") return;

    final fileContent = await File(file.path!).readAsString();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Stats(file: fileContent,)),
    );
  }

  //!lang opt einbauen 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: Icon(Icons.upload_file),
            onPressed: () => pickFile(context),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade800),
                color: Colors.grey.shade200,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                """Um ChatWrapped zu nutzen, musst du den Chat direkt innerhalb von WhatsApp exportieren.
WhatsApp erstellt dabei eine ZIP-Datei, die du anschließend entpacken musst.
Danach lädst du die entpackten Dateien hier hoch, damit ChatWrapped sie auswerten kann."""),
              ),
            ),
          )
        ],
      ),
    );
  }
}