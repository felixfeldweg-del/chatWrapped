import 'package:chatstats/CountUpWidget.dart';
import 'package:chatstats/Message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

String patternsJson = '''
  {
  "MEDIA" : "<Medien ausgeschlossen>",
  "EDITED" : "<Diese Nachricht wurde bearbeitet.>",
  "DELETEDME" : "Du hast diese Nachricht gelöscht.",
  "DELETEDOTHERS" : "Diese Nachricht wurde gelöscht.",
  }
  ''';

Map<String, dynamic> rawMap = jsonDecode(patternsJson);

Map<MessageType, String> patterns = {
  for (var entry in rawMap.entries)
    MessageType.values.firstWhere(
          (e) => e.toString().split('.').last == entry.key,
        ):
        entry.value,
};

class Stats extends StatelessWidget {
  final String file;
  final messageStart = RegExp(
    r'(?=\d{2}\.\d{2}\.\d{2}, \d{2}:\d{2} - .+?:)',
  ); //? Change here the format

  final int minWordLenght = 6;

  Stats({super.key, required this.file});

  List<String> splitMessages(String file) {
    return file.split(messageStart).where((m) => m.trim().isNotEmpty).toList();
  }

  List<Message> stringsToMessages(List<String> messages) {
    List<Message> messagesList = [];

    RegExp messageReg = RegExp(
      r'^(\d{2})\.(\d{2})\.(\d{2}), (\d{2}):(\d{2}) - (.+?): (.*)',
    );

    for (String message in messages) {
      final match = messageReg.firstMatch(message);
      if (match == null) continue;

      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final min = int.parse(match.group(5)!);
      final author = match.group(6)!;
      final content = match.group(7)!;

      DateTime time = DateTime(year + 2000, month, day, hour, min);

      messagesList.add(Message(content: content, author: author, time: time));
    }
    return messagesList;
  }

  int totalLetters(List<Message> messages) {
    int count = 0;
    for (var message in messages) {
      count += message.letters;
    }
    return count;
  }

  List<String> allWords(List<Message> messages) {
    List<String> all = [];
    for (var message in messages) {
      all.addAll(message.words);
    }
    return all;
  }

  Message longestMessage(List<Message> messages) {
    Message longest = messages[0];

    for (var message in messages) {
      if (message.letters > longest.letters) {
        longest = message;
      }
    }
    return longest;
  }

  Map<String, int> countMessagesPerPerson(List<Message> messages) {
    Map<String, int> perPerson = {};

    for (Message mes in messages) {
      perPerson.update(mes.author, (value) => value + 1, ifAbsent: () => 1);
    }
    return sortMap<String, int>(perPerson);
  }
//! DEPRECATED
  List<Message> findString(String pattern, List<Message> messages) {
    return messages.where((m) => m.content.contains(pattern)).toList();
  }
//!
  List<Message> findFlags(MessageType pattern, List<Message> messages) {
    return messages.where((m) => m.flags.contains(pattern)).toList();
  }

  Map<String, Duration> messageAnswerTime(List<Message> messages) {
    Map<String, List<Duration>> time = {};

    for (int i = 1; i < messages.length; i++) {
      final prev = messages[i - 1];
      final curr = messages[i];

      if (prev.author != curr.author) {
        final diff = curr.time.difference(prev.time);

        time.putIfAbsent(curr.author, () => []);
        time[curr.author]!.add(diff);
      }
    }

    Map<String, Duration> averages = {};

    time.forEach((author, durations) {
      final totalMin = durations
          .map((d) => d.inMinutes)
          .reduce((a, b) => a + b);
      final avgMin = totalMin ~/ durations.length;
      averages[author] = Duration(minutes: avgMin);
    });

    
    return sortMap<String, Duration>(averages);
  }

  Map<K, V> sortMap<K, V extends Comparable>(Map<K, V> map, {bool descending = true}) {
    final entries = map.entries.toList()
      ..sort((a, b) => 
        descending ? b.value.compareTo(a.value)
                   : a.value.compareTo(b.value));


    return {for (var e in entries) e.key: e.value};
  }
//! DEPRECATED?
  int averageTotalTime(List<Message> messages, DateTime firstTime) {
    final totalDur = DateTime.now().difference(firstTime);

    return (totalDur.inMinutes / messages.length).round();
  }
//!
  Map<String, int> wordAmount(List<Message> messages) {

    Map<String, int> wordAmounts = {};

    for (var message in messages) {
        List<String> filteredWords = message.words.where((word)=> word.length > minWordLenght).toList();
        for(String word in filteredWords){
          wordAmounts.update(
            word,
            (count) => count +1,
            ifAbsent: () => 1
          );
        }
      }
      return sortMap<String, int>(wordAmounts);
    }


// TODO OPTEMIZE FROM HERE ON 
  @override
  Widget build(BuildContext context) {
    final splitedMessages = splitMessages(file);
    final messages = stringsToMessages(
      splitedMessages,
    ); // Wegen erste und letzte Line
    final messagesLastYear = messages.where((mes) => mes.inLastYear()).toList();
    final letters = totalLetters(messages);
    final longest = longestMessage(messages);
    final messagesPerPerson = countMessagesPerPerson(messages);
    final authors = messagesPerPerson.keys.toList();
    final media = countMessagesPerPerson(
      findFlags(MessageType.MEDIA, messages),
    );
    final editedMessages = countMessagesPerPerson(
      findFlags(MessageType.EDITED, messages),
    );
    final deletedMessagesYou = findFlags(MessageType.DELETEDME, messages);
    final deletedMessagesOthers = countMessagesPerPerson(
      findFlags(MessageType.DELETEDOTHERS, messages),
    );
    final secertetMessages = countMessagesPerPerson(
      messages.where((m) => m.content.trim().isEmpty).toList(),
    );
    final messageTime = messageAnswerTime(messages);
    final firstTime = messages[0].time;
    final totalTimeAvg = averageTotalTime(messages, firstTime);
    final mostMessages = wordAmount(messages);

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(height: screenHeight / 2 - 25),
              Text(
                'Lets get Started:',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),

              Container(height: screenHeight / 2),
              Text(
                'Total Messages',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),
              CountUpAnimation(endValue: messages.length),
              Text(
                'Last 365 days ',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),
              CountUpAnimation(endValue: messagesLastYear.length),

              Container(height: screenHeight / 2),
              Text(
                'Thats',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),

              CountUpAnimation(endValue: letters),
              Text(
                'Letters or',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),
              CountUpAnimation(endValue: (letters / messages.length).round()),
              Text(
                'per Message',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),

              Container(height: screenHeight / 2),
              Text(
                'The longest Message',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  '$longest',
                  style: GoogleFonts.fugazOne(fontSize: 20),
                ),
              ),

              if (authors.isNotEmpty) ...[
                Container(height: screenHeight / 2),
                for (int i = 0; i < authors.length; i++) ...[
                  Text(
                    '${authors[i]} wrote',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(
                    endValue:
                        (messagesPerPerson[authors[i]]! *
                                100.0 /
                                messages.length)
                            .round(),
                    precentage: true,
                  ),
                  CountUpAnimation(
                    endValue: messagesPerPerson[authors[i]]!,
                    fontSize: 30,
                  ),
                ],
              ],

              if (editedMessages.isNotEmpty) ...[
                Container(height: screenHeight / 2),
                for (int i = 0; i < editedMessages.keys.length; i++) ...[
                  Text(
                    '${editedMessages.keys.toList()[i]} edited',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(
                    endValue: editedMessages[editedMessages.keys.toList()[i]]!,
                  ),
                ],
                Text(
                  'Messages',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
              ],

              if (media.isNotEmpty) ...[
                Container(height: screenHeight / 2),
                for (int i = 0; i < media.keys.length; i++) ...[
                  Text(
                    '${media.keys.toList()[i]} send',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(endValue: media[media.keys.toList()[i]]!),
                ],
                Text(
                  'Media',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
              ],

              Container(height: screenHeight / 2),
              if (deletedMessagesOthers.isNotEmpty) ...[
                for (int i = 0; i < deletedMessagesOthers.keys.length; i++) ...[
                  Text(
                    '${deletedMessagesOthers.keys.toList()[i]} deleted',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(
                    endValue:
                        deletedMessagesOthers[deletedMessagesOthers.keys
                            .toList()[i]]!,
                  ),
                ],
              ],
              if (deletedMessagesYou.isNotEmpty) ...[
                Text(
                  'You deleted',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
                CountUpAnimation(endValue: deletedMessagesYou.length),
                Text(
                  'Messages',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
              ],

              if (secertetMessages.isNotEmpty) ...[
                Container(height: screenHeight / 2),
                for (int i = 0; i < secertetMessages.keys.length; i++) ...[
                  Text(
                    '${secertetMessages.keys.toList()[i]} had',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(
                    endValue:
                        secertetMessages[secertetMessages.keys.toList()[i]]!,
                  ),
                ],
                Text(
                  'secrets and calls',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
              ],

              if (messageTime.isNotEmpty) ...[
                Container(height: screenHeight / 2),
                for (int i = 0; i < messageTime.keys.length; i++) ...[
                  Text(
                    '${messageTime.keys.toList()[i]} had',
                    style: GoogleFonts.fugazOne(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  CountUpAnimation(
                    endValue:
                        messageTime[messageTime.keys.toList()[i]]!.inMinutes,
                  ),
                ],
                Text(
                  'min answertime',
                  style: GoogleFonts.fugazOne(fontSize: 50),
                  textAlign: TextAlign.center,
                ),
              ],

              Container(height: screenHeight / 2),

              CountUpAnimation(endValue: totalTimeAvg),
              Text(
                'min per message',
                style: GoogleFonts.fugazOne(fontSize: 50),
                textAlign: TextAlign.center,
              ),

              //MEDIEN  ✔
              //Häufigstes wort
              //Antwort zeit ✔
              //Streak 5 min + tage
              // Tag mit meisten nachrichten
              // zeit raum

              //! widget für einzelne teile mit Textbefore, after count, und abstand machen, alle styles custom
            ],
          ),
        ),
      ),
    );
  }
}


