import 'dart:convert';
import 'dart:html';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICS Converter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _icsContent = '';
  TextEditingController textController = TextEditingController();

  void _convertToICS(String input) {
    final rows = const LineSplitter().convert(input);
    final headers = rows.first.split(',');
    List<String> events = [];

    for (var i = 1; i < rows.length; i++) {
      List<String> data = rows[i].split(',');
      Map<String, String> event = Map.fromIterables(headers, data);
      String uid = const Uuid().v4() + '@example.com';
      String startDate = event['Start Date']!.replaceAll('/', '');
      String endDate = event['End Date']!.replaceAll('/', '');

      String eventBlock = """
BEGIN:VEVENT
DTSTART;VALUE=DATE:$startDate
DTEND;VALUE=DATE:${endDate}T235959
DTSTAMP:${DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z
UID:$uid
CREATED:${DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z
DESCRIPTION:<a href="${event['URL']}" target="_blank">${event['URL']}</a>
LAST-MODIFIED:${DateTime.now().toUtc().toString().replaceAll('-', '').replaceAll(':', '').split('.')[0]}Z
SEQUENCE:0
STATUS:CONFIRMED
SUMMARY:${event['Subject']}
TRANSP:TRANSPARENT
END:VEVENT""";
      events.add(eventBlock);
    }

    setState(() {
      _icsContent = """
BEGIN:VCALENDAR
PRODID:-//Google Inc//Google Calendar 70.9054//EN
VERSION:2.0
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:ICS Events
X-WR-TIMEZONE:UTC
${events.join('\n')}
END:VCALENDAR""";
    });
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _icsContent));
  }

  void _downloadICS() {
    final blob = Blob([_icsContent]);
    final url = Url.createObjectUrlFromBlob(blob);
    AnchorElement(href: url)
      ..setAttribute('download', 'events.ics')
      ..click();
    Url.revokeObjectUrl(url);
  }

  Future<void> _pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      final contents = utf8.decode(file.bytes!);
      _convertToICS(contents);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICS Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickAndReadFile,
              child: const Text('Upload CSV/Text File'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste CSV text here',
                labelText: 'Input Text',
              ),
              maxLines: 10,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _convertToICS(textController.text),
              child: const Text('Convert to ICS'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_icsContent.isEmpty
                    ? 'No data converted yet.'
                    : _icsContent),
              ),
            ),
            Row(
              children: [
                if (_icsContent.isNotEmpty)
                  ElevatedButton(
                    onPressed: _copyContent,
                    child: const Text('Copy to Clipboard'),
                  ),
                const SizedBox(width: 20),
                if (_icsContent.isNotEmpty)
                  ElevatedButton(
                    onPressed: _downloadICS,
                    child: const Text('Download ICS File'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
