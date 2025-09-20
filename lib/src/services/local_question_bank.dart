class LocalQuestionBank {
  static Map<String, dynamic> one(String category, int rating) {
    final c = category.toLowerCase();
    final bank = <String, List<List<String>>>{
      'general': [
        ['Which planet is known as the Red Planet?', 'Mars', 'Venus', 'Jupiter', 'Mercury'],
        ['What gas do plants absorb for photosynthesis?', 'Carbon dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen'],
      ],
      'history': [
        ['Who was the first President of the United States?', 'George Washington', 'Abraham Lincoln', 'John Adams', 'Thomas Jefferson'],
        ['In which year did World War II end?', '1945', '1939', '1942', '1948'],
      ],
      'geography': [
        ['How many continents are there?', '7', '5', '6', '8'],
        ['What is the largest ocean?', 'Pacific Ocean', 'Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
      ],
      'science': [
        ['What is H2O?', 'Water', 'Hydrogen', 'Oxygen', 'Salt'],
        ['What is the speed of light (approx)?', '300,000 km/s', '30,000 km/s', '3,000 km/s', '300 km/s'],
      ],
      'sports': [
        ['How many players on a soccer team (on field)?', '11', '9', '10', '12'],
        ['In which sport is Wimbledon played?', 'Tennis', 'Golf', 'Cricket', 'Rugby'],
      ],
      'movies': [
        ['Who directed “Jurassic Park”?', 'Steven Spielberg', 'James Cameron', 'Ridley Scott', 'Christopher Nolan'],
        ['Which movie features the quote “May the Force be with you”?', 'Star Wars', 'The Matrix', 'Blade Runner', 'Avatar'],
      ],
      'music': [
        ['Which composer wrote the Fifth Symphony?', 'Beethoven', 'Mozart', 'Bach', 'Tchaikovsky'],
        ['Which instrument has keys, pedals, and strings?', 'Piano', 'Flute', 'Drums', 'Violin'],
      ],
    };

    final items = bank[c] ?? bank['general']!;
    final q = (items..shuffle()).first;
    final text = q[0];
    final correct = q[1];
    final options = [q[1], q[2], q[3], q[4]]..shuffle();
    final answerIndex = options.indexOf(correct);

    return {
      'text': text,
      'options': options,
      'answerIndex': answerIndex,
      'category': category,
      'difficulty': rating,
      'fallback': true,
    };
  }
}
