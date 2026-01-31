
import 'package:chatstats/Stats.dart';

enum MessageType {TEXT, EDITED, DELETEDME, DELETEDOTHERS, MEDIA, SECRET}

class Message {

  final String content;
  String cleanContent;
  final DateTime time;
  final String author;
  final List<MessageType> flags;

  int get letters => cleanContent.length;
  List<String> get words => cleanContent.split("");

  bool get isMedia => flags.contains(MessageType.MEDIA);
  bool get isEDITED => flags.contains(MessageType.EDITED);
  bool get isDELETED => flags.contains(MessageType.DELETEDME);
  bool get isSECRET => flags.contains(MessageType.SECRET);


  Message({
    required this.content,
    required this.author, 
    required this.time,
  }) 
  : flags = [],
  cleanContent = content
  {
    for (var entry in patterns.entries) {   
      if (content.contains(entry.value)) {
        flags.add(entry.key);
        cleanContent = content.replaceAll(entry.value, "");
        break; 
      }
    }
    if(flags.isEmpty){
      flags.add(MessageType.TEXT);
    }
  }

  bool inLastYear(){
    final oneYearAgo = DateTime.now().subtract(Duration(days: 365));
    return time.isAfter(oneYearAgo);
  }
}
