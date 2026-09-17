/// Matching a typed query against diary text and photo captions.
///
/// **Diacritics and case do not count.** A phone keyboard makes `š` a
/// long-press away, so the same word gets written both ways across a year of
/// entries - and a search that finds `tuzna` but not `tužna` finds half of
/// what she wrote.
library;

const _folds = {
  'š': 's',
  'đ': 'd',
  'č': 'c',
  'ć': 'c',
  'ž': 'z',
};

/// Lower case, Serbian diacritics dropped, `dj` read as `d` so `đ` and its
/// two-letter spelling land on the same key.
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_folds[char] ?? char);
  }
  return buffer.toString().replaceAll('dj', 'd');
}

/// Whether [text] holds every word of [query], in any order.
///
/// Every word rather than the whole phrase, because "posao umorna" is how a
/// person remembers an entry and never how they wrote it. An empty query
/// matches nothing: a search screen that lists every entry before a letter is
/// typed is a diary reader, which is the day detail screen's job.
bool matchesQuery(String text, String query) {
  final words = foldForSearch(query)
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return false;
  final haystack = foldForSearch(text);
  return words.every(haystack.contains);
}
