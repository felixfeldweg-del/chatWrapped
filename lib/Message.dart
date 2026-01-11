class Message {

  final String content;
  final DateTime time;
  final String author;

  int get length => content.length;

  Message({
    required this.content,
    required this.author, 
    required this.time
  });

  bool inLastYear(){
    DateTime now = DateTime.now();
    final oneYearAgo = DateTime(now.year -1, now.month, now.day);

    return time.isAfter(oneYearAgo);
  }
}
