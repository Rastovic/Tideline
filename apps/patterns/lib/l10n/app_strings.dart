import 'package:patterns_core/patterns_core.dart';

import 'app_language.dart';

/// Every word the app shows, in both languages, side by side.
///
/// One file rather than one per language, so a string added in English is
/// visibly missing its Serbian twin in the same line of the same review.
final class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  String _t(String en, String sr) => language == AppLanguage.en ? en : sr;

  // --- Shared -----------------------------------------------------------
  String get cancel => _t('Cancel', 'Odustani');
  String get delete => _t('Delete', 'Obrisi');
  String get save => _t('Save', 'Sacuvaj');
  String get log => _t('Log', 'Zabiljezi');

  // --- The type system --------------------------------------------------
  String kindName(MetricKind kind) => switch (kind) {
    MetricKind.scale => _t('Rating', 'Ocjena'),
    MetricKind.percent => _t('Percent', 'Postotak'),
    MetricKind.count => _t('Count', 'Broj'),
    MetricKind.duration => _t('Duration', 'Trajanje'),
    MetricKind.amount => _t('Amount', 'Kolicina'),
    MetricKind.boolean => _t('Yes or no', 'Da ili ne'),
    MetricKind.choice => _t('One choice', 'Jedan izbor'),
    MetricKind.tags => _t('Several choices', 'Vise izbora'),
    MetricKind.text => _t('Text', 'Tekst'),
    MetricKind.photo => _t('Photo', 'Fotografija'),
    MetricKind.timeOfDay => _t('Time', 'Vrijeme'),
  };

  String kindHint(MetricKind kind) => switch (kind) {
    MetricKind.scale => _t(
      'A slider between two ends you set',
      'Klizac izmedju dvije granice koje sama postavis',
    ),
    MetricKind.percent => _t(
      '0 to 100, in steps of five',
      '0 do 100, u koracima od pet',
    ),
    MetricKind.count => _t(
      'How many times. Glasses of water, cigarettes',
      'Koliko puta. Case vode, cigarete',
    ),
    MetricKind.duration => _t('Hours and minutes', 'Sati i minute'),
    MetricKind.amount => _t(
      'A number with a unit. Dose, weight',
      'Broj s jedinicom. Doza, tezina',
    ),
    MetricKind.boolean => _t(
      'It happened or it did not',
      'Bilo je ili nije bilo',
    ),
    MetricKind.choice => _t(
      'Exactly one option from your list',
      'Tacno jedna opcija s tvoje liste',
    ),
    MetricKind.tags => _t(
      'Any number of options from your list',
      'Koliko god opcija s tvoje liste',
    ),
    MetricKind.text => _t('Free text. A diary', 'Slobodan tekst. Dnevnik'),
    MetricKind.photo => _t('A photo with a caption', 'Slika s opisom'),
    MetricKind.timeOfDay => _t(
      'A time of day. Bedtime, waking up',
      'Sat u danu. Lijeganje, ustajanje',
    ),
  };

  String aggregationName(DayAggregation rule) => switch (rule) {
    DayAggregation.sum => _t('Sum', 'Zbir'),
    DayAggregation.typical => _t('Typical', 'Tipicno'),
    DayAggregation.peak => _t('Highest', 'Najvise'),
    DayAggregation.lowest => _t('Lowest', 'Najmanje'),
    DayAggregation.last => _t('Last', 'Zadnje'),
    DayAggregation.anyTrue => _t('True at any point', 'Bilo kad tacno'),
    DayAggregation.union => _t('Everything together', 'Sve zajedno'),
    DayAggregation.none => _t('Each entry separately', 'Svaki unos posebno'),
  };

  String aggregationHint(DayAggregation rule) => switch (rule) {
    DayAggregation.sum => _t(
      '3 g and 2 g on the same day make 5 g',
      '3 g i 2 g istog dana su 5 g',
    ),
    DayAggregation.typical => _t(
      'The median, not the mean',
      'Medijana, ne prosjek',
    ),
    DayAggregation.peak => _t(
      'The peak of the day. For bloating and pain',
      'Vrhunac dana. Za nadutost i bol',
    ),
    DayAggregation.lowest => _t(
      'The lowest value of the day',
      'Najniza vrijednost dana',
    ),
    DayAggregation.last => _t(
      'The latest entry by time',
      'Posljednji unos po vremenu',
    ),
    DayAggregation.anyTrue => _t(
      'The day counts if it happened even once',
      'Dan se broji ako je bilo makar jednom',
    ),
    DayAggregation.union => _t(
      'Everything marked that day',
      'Sve sto je taj dan oznaceno',
    ),
    DayAggregation.none => _t('Not combined', 'Bez sazimanja'),
  };

  String displayName(DisplayStyle style) => switch (style) {
    DisplayStyle.squares => _t('Squares', 'Kvadratici'),
    DisplayStyle.bars => _t('Bars', 'Stupci'),
    DisplayStyle.dots => _t('Dots', 'Tacke'),
    DisplayStyle.brokenLine => _t('Broken line', 'Prekinuta linija'),
    DisplayStyle.presenceStrip => _t('Presence strip', 'Traka prisustva'),
    DisplayStyle.backgroundBand => _t('Background band', 'Pozadinska traka'),
    DisplayStyle.tagRows => _t('Row per option', 'Red po opciji'),
  };

  String domainName(MetricDomain domain) => switch (domain) {
    MetricDomain.mind => _t('MIND', 'UM'),
    MetricDomain.body => _t('BODY', 'TIJELO'),
    MetricDomain.cycle => _t('CYCLE', 'CIKLUS'),
  };

  // --- Dates ------------------------------------------------------------
  List<String> get months => language == AppLanguage.en
      ? const [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ]
      : const [
          'januar',
          'februar',
          'mart',
          'april',
          'maj',
          'jun',
          'jul',
          'avgust',
          'septembar',
          'oktobar',
          'novembar',
          'decembar',
        ];

  /// Two or three letters, because two weekdays share an initial in both.
  List<String> get weekdays => language == AppLanguage.en
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['pon', 'uto', 'sri', 'cet', 'pet', 'sub', 'ned'];

  /// `2026-08-19` as `19 August` / `19. avgust`, with the year on request.
  ///
  /// No weekday and no relative wording: "today" on a screen opened at 01:00
  /// with a 04:00 day boundary is a lie.
  String humanDate(String dayKey, {bool withYear = false}) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return dayKey;
    final month = months[((int.tryParse(parts[1]) ?? 1) - 1).clamp(0, 11)];
    final day = int.tryParse(parts[2]) ?? 1;
    return language == AppLanguage.en
        ? (withYear ? '$day $month ${parts[0]}' : '$day $month')
        : (withYear ? '$day. $month ${parts[0]}.' : '$day. $month');
  }

  /// `2026-09` as `September 2026` / `septembar 2026.`
  String monthYear(String yearMonth) {
    final month = months[(int.parse(yearMonth.substring(5)) - 1).clamp(0, 11)];
    final year = yearMonth.substring(0, 4);
    return _t('$month $year', '$month $year.');
  }

  /// `1.8.` style short date, used where a chip is narrow. Same in both.
  String shortDate(int day, int month, [int? year]) =>
      year == null ? '$day.$month.' : '$day.$month.$year.';

  // --- Home --------------------------------------------------------

  String get search => _t('Search', 'Pretraga');
  String get dayDetail => _t('Day detail', 'Detalji dana');
  String get reports => _t('Reports', 'Izvjestaji');
  String get markers => _t('Markers', 'Markeri');
  String get settings => _t('Settings', 'Podesavanja');

  // --- Logging -----------------------------------------------------

  String get captureUnavailable => _t(
    'Taking a photo is not available here.',
    'Slikanje nije dostupno ovdje.',
  );
  String get takePhoto => _t('Take photo', 'Slikaj');
  String get fromGallery => _t('From gallery', 'Iz galerije');
  String get photosStayInApp => _t(
    'Photos stay in the app, never in the gallery.',
    'Fotografije ostaju u aplikaciji, nikad u galeriji.',
  );
  String get didNotHappen => _t('It did not', 'Nije bilo');
  String get happened => _t('It did', 'Bilo je');
  String get noneOfTheseButton => _t('None of these', 'Nista od ovoga');
  String get noneOfThese => _t('none of these', 'nista od ovoga');
  String get newEntry => _t('New entry', 'Novi unos');
  String get editingToday =>
      _t("Editing today's entry", 'Mijenjas danasnji unos');
  String get addingToday =>
      _t('Another entry for today', 'Jos jedan unos za danas');
  String get diaryHint =>
      _t('How it went, and why', 'Kako je bilo, i zbog cega');
  String get private => _t('Private', 'Privatno');
  String get privateLower => _t('private', 'privatno');
  String get privateExplained => _t(
    'Never shown in search or on the doctor page',
    'Ne pojavljuje se u pretrazi ni na stranici za doktora',
  );
  String get yes => _t('yes', 'da');
  String get no => _t('no', 'ne');
  String get photoLower => _t('photo', 'fotografija');

  // --- Days, photos, search ----------------------------------------

  String get goToDay => _t('Go to day', 'Idi na dan');
  String get previousDay => _t('Previous day', 'Prethodni dan');
  String get nextDay => _t('Next day', 'Sljedeci dan');
  String get addEntry => _t('Add entry', 'Dodaj unos');
  String get photoOfTheDay => _t('Photo of the day', 'Fotografija dana');
  String get deleteEntryQuestion => _t('Delete entry?', 'Obrisati unos?');
  String get entry => _t('Entry', 'Unos');
  String cycleDay(int day) => _t('cycle day $day', 'dan ciklusa $day');
  String get nothingLogged => _t('Nothing logged.', 'Nista zabiljezeno.');
  String get unknownMarker => _t('unknown marker', 'nepoznat marker');
  String get enteredLate => _t('entered later', 'uneseno naknadno');
  String get fileMissing => _t('file missing', 'fajl nedostaje');
  String get deletePhotoQuestion =>
      _t('Delete photo?', 'Obrisati fotografiju?');
  String get deletePhotoExplained => _t(
    'The file is deleted from the phone. This cannot be undone.',
    'Fajl se brise sa telefona. Ovo se ne vraca.',
  );
  String get caption => _t('Caption', 'Opis');
  String get captionHint => _t('e.g. after training', 'npr. poslije treninga');
  String get noPhotosYet => _t('No photos yet.', 'Jos nema fotografija.');
  String get searchHint => _t(
    'Search the diary and photo captions',
    'Pretrazi dnevnik i opise fotografija',
  );
  String get includePrivate => _t('Include private', 'Ukljuci privatne');
  String get nothingFound =>
      _t('Nothing contains those words.', 'Nista ne sadrzi te rijeci.');

  // --- Reports and export ------------------------------------------

  String get deleteReportQuestion =>
      _t('Delete report?', 'Obrisati izvjestaj?');
  String get deleteReportExplained => _t(
    'No entry is touched. A report is only a question asked of the data.',
    'Nijedan unos se ne dira. Izvjestaj je samo pitanje nad podacima.',
  );
  String get export => _t('Export', 'Izvoz');
  String get doctorPage => _t('Doctor page', 'Stranica za doktora');
  String get newReport => _t('New report', 'Novi izvjestaj');
  String get report => _t('Report', 'Izvjestaj');
  String get noReportsYet => _t(
    'None yet. A report is a set of markers and a period - rows stacked on '
        'one time axis, so you can read them side by side.',
    'Jos nijedan. Izvjestaj je set markera i period - slozeni redovi na '
        'istoj vremenskoj osi, da ih citas jedan uz drugi.',
  );
  String window(int days) => switch (days) {
    7 => _t('7 days', '7 dana'),
    30 => _t('month', 'mjesec'),
    90 => _t('3 months', '3 mjeseca'),
    180 => _t('6 months', '6 mjeseci'),
    365 => _t('year', 'godina'),
    _ => _t('$days days', '$days dana'),
  };
  String get all => _t('all', 'sve');
  String markerCount(int n) =>
      _t(n == 1 ? '1 marker' : '$n markers', '$n markera');
  String get edit => _t('Edit', 'Izmijeni');
  String get saveAsReport => _t('Save as report', 'Sacuvaj kao izvjestaj');
  String get reportMarkersGone => _t(
    'None of the markers in this report exist any more.',
    'Nijedan marker u ovom izvjestaju vise ne postoji.',
  );
  String get byDate => _t('By date', 'Po datumu');
  String get reportTapHint => _t(
    'Tap any day on a chart to see that entry with its note and photos.',
    'Dodirni bilo koji dan na grafu da vidis unos sa notes i slikama.',
  );
  String get notesAndPhotos => _t('Notes and photos', 'Notes i slike');
  String get byCycleDay => _t('By cycle day', 'Po danu ciklusa');
  String get grid => _t('Grid', 'Mreza');
  String behind(String name) => _t('behind: $name', 'iza: $name');
  String get typical => _t('typical', 'tipicno');
  String get weekly => _t('weekly', 'tjedno');
  String daysOf(int logged, int total) =>
      _t('$logged/$total days', '$logged/$total dana');
  String get dateRange => _t('Date range', 'Raspon datuma');
  String get use => _t('Use', 'Uzmi');
  String get nameTheReport =>
      _t('Give the report a name.', 'Daj izvjestaju ime.');
  String get pickAtLeastOneMarker =>
      _t('Pick at least one marker.', 'Izaberi bar jedan marker.');
  String get name => _t('Name', 'Ime');
  String get reportNameHint =>
      _t('creatine and bloating', 'kreatin i nadutost');
  String get period => _t('Period', 'Period');
  String get axis => _t('Axis', 'Osa');
  String get order => _t('Order', 'Redoslijed');
  String move(String name) => _t('Move $name', 'Pomjeri $name');
  String get asBandBehind => _t('As a band behind...', 'Kao traka iza...');
  String get ownRow => _t('Its own row', 'Svoj red');
  String get exportFor => _t('For', 'Za sta');
  String get forAi => _t('For AI', 'Za AI');
  String get spreadsheetCsv => _t('Spreadsheet (CSV)', 'Tabela (CSV)');
  String get intro => _t('Intro', 'Uvod');
  String get whatGoesIn => _t('What goes in the file', 'Sta ide u fajl');
  String exportRowCount(int n) =>
      _t('$n entries go in the file.', '$n unosa ide u fajl.');
  String get photosNever => _t('Photos: never.', 'Fotografije: nikad.');
  String privateHeldBack(int n) => _t(
    'Private diary entries left out: $n.',
    'Privatni unosi dnevnika izostavljeni: $n.',
  );
  String diaryHeldBack(int n) => _t(
    'Diary not ticked, left out: $n.',
    'Dnevnik nije izabran, izostavljeno: $n.',
  );
  String get shareFile => _t('Share file', 'Podijeli fajl');

  // --- Backup ------------------------------------------------------

  String get archive => _t('Backup', 'Arhiva');
  String get archiveReady => _t('Backup is ready', 'Arhiva je spremna');
  String get share => _t('Share', 'Podijeli');
  String get archiveNotSent =>
      _t('The backup was not sent anywhere.', 'Arhiva nije nigdje poslana.');
  String get nothingLoaded => _t('Nothing was loaded.', 'Nista nije ucitano.');
  String get nothingChanged =>
      _t('Nothing was changed.', 'Nista nije promijenjeno.');
  String get restoreQuestion =>
      _t('Restore this backup?', 'Vratiti ovu arhivu?');
  String get restore => _t('Restore', 'Vrati');
  String get archiveExplained => _t(
    'One file with everything: markers, entries, reports and photos. The '
        'photos are inside, not next to it - a backup that quietly leaves out '
        'half of what you would miss is not a backup.',
    'Jedan fajl sa svime: markeri, unosi, izvjestaji i fotografije. '
        'Fotografije su unutra, ne pored - arhiva koja tiho izostavi pola '
        'onoga za cim bi zalila nije arhiva.',
  );
  String get makeArchive => _t('Make a backup', 'Napravi arhivu');
  String get restoreFromArchive => _t('Restore from backup', 'Vrati iz arhive');
  String get restoreExplained => _t(
    'Restoring replaces everything now in the app. It shows you what is in '
        'the file first.',
    'Vracanje zamjenjuje sve sto je sada u aplikaciji. Prvo ti pokaze sta je '
        'u fajlu.',
  );
  String get refusedMalformed => _t(
    'This is not a backup from this app. Nothing was changed.',
    'Ovo nije arhiva ove aplikacije. Nista nije promijenjeno.',
  );
  String get refusedFuture => _t(
    'This backup was made by a newer version of the app. Nothing was '
        'written - half an import would be worse than none.',
    'Ova arhiva je napravljena novijom verzijom aplikacije. Nista nije '
        'upisano - pola uvoza bi bilo gore od nijednog.',
  );
  String get refusedDamaged => _t(
    'The file is damaged, so it cannot be trusted. Nothing was changed.',
    'Fajl je ostecen, pa mu se ne moze vjerovati. Nista nije promijenjeno.',
  );
  String get refusedIncomplete => _t(
    'Part of the backup is missing. It may not have finished saving. '
        'Nothing was changed.',
    'Arhivi nedostaje dio. Mozda se nije do kraja sacuvala. Nista nije '
        'promijenjeno.',
  );
  String photoCount(int n) =>
      _t(n == 1 ? '1 photo' : '$n photos', '$n fotografija');
  String photosWithoutFile(int n) => _t(
    '$n photos have no file on disk and are not in the backup.',
    '$n fotografija nema fajl na disku i nije usla u arhivu.',
  );
  String dayRange(String from, String to) => _t('$from to $to', '$from do $to');
  String entriesAndPhotos(int entries, int photos) => _t(
    '$entries entries and $photos photos',
    '$entries unosa i $photos fotografija',
  );
  String get replacesEverything => _t(
    'This replaces everything now in the app.',
    'Ovo zamjenjuje sve sto je sada u aplikaciji.',
  );
  String restored(int rows, int photos) => _t(
    '$rows rows restored, $photos photos.',
    '$rows redova vraceno, $photos fotografija.',
  );
  String photosNotInArchive(int n) => _t(
    '$n photos were not in the backup - the days and captions are here, the '
        'images are not.',
    '$n fotografija nije bilo u arhivi - dani i opisi su tu, same slike nisu.',
  );

  // --- Settings ----------------------------------------------------

  String get reminderHeading => _t('REMINDER', 'PODSJETNIK');
  String get oneEveningReminder =>
      _t('One evening reminder', 'Jedan podsjetnik uvece');
  String get time => _t('Time', 'Vrijeme');
  String get reminderPromise => _t(
    'It says the same thing every evening and opens the marker list. It does '
        'not know whether you logged anything and never mentions a missed day.',
    'Kaze isto svake veceri i otvara listu markera. Ne zna da li si nesto '
        'upisala i ne spominje propusteni dan.',
  );
  String get reminderBody =>
      _t('Write down how it went.', 'Upisi kako je bilo.');
  String get lockHeading => _t('LOCK', 'ZAKLJUCAVANJE');
  String get lockTitle =>
      _t('Fingerprint or phone PIN', 'Otisak ili PIN telefona');
  String get lockExplained => _t(
    'On opening and after a minute away. Turning it off needs an unlock.',
    'Pri otvaranju i nakon minute van aplikacije. Za iskljucivanje treba '
        'otkljucati.',
  );
  String get lockUnavailable => _t(
    'The phone has no screen lock, so the app cannot be locked.',
    'Telefon nema zakljucan ekran, pa aplikacija ne moze biti zakljucana.',
  );
  String get unlockReason => _t('Unlock Tideline', 'Otkljucaj Tideline');
  String get locked => _t('Tideline is locked', 'Tideline je zakljucan');
  String get unlock => _t('Unlock', 'Otkljucaj');
  String get widgetHeading =>
      _t('HOME SCREEN WIDGET', 'WIDGET NA POCETNOM EKRANU');
  String widgetExplained(int slots) => _t(
    'Up to $slots markers. The widget shows names only, never values or '
        'whether anything was logged.',
    'Do $slots markera. Widget prikazuje samo imena, nikad vrijednosti ni da '
        'li je nesto upisano.',
  );
  String get widgetEmpty =>
      _t('Pick markers in Settings', 'Izaberi markere u Podesavanjima');
  String get dayHeading => _t('DAY', 'DAN');
  String get newDayStartsAt => _t('A new day starts at', 'Novi dan pocinje u');
  String get dayBoundaryExplained => _t(
    'An entry at 01:30 belongs to the day that just ended. A change applies '
        'to new entries; old ones stay where they are.',
    'Unos u 01:30 pripada danu koji se upravo zavrsio. Promjena vazi za nove '
        'unose; stari ostaju gdje su.',
  );
  String get archiveHeading => _t('BACKUP', 'ARHIVA');
  String get photosTakeUp => _t('Photos take up', 'Fotografije zauzimaju');
  String get backupAndRestore => _t('Backup and restore', 'Backup i vracanje');
  String get oneFileWithEverything => _t(
    'One file with everything, photos inside',
    'Jedan fajl sa svime, fotografije unutra',
  );
  String get notificationsBlocked => _t(
    'Notifications are turned off in the phone settings, so the reminder '
        'cannot arrive. Everything else works normally.',
    'Obavjestenja su iskljucena u postavkama telefona, pa podsjetnik ne moze '
        'stici. Sve ostalo radi normalno.',
  );

  // --- Camera ------------------------------------------------------

  String get noCamera => _t('The phone has no camera.', 'Telefon nema kameru.');
  String get cameraNotAllowed => _t(
    'The camera is not allowed. Permission is given in the phone settings.',
    'Kamera nije dozvoljena. Dozvola se daje u postavkama telefona.',
  );
  String get cameraFailed =>
      _t('The camera could not be opened.', 'Kamera se nije mogla otvoriti.');
  String get hidePreviousPhoto =>
      _t('Hide previous photo', 'Sakrij prethodnu fotografiju');
  String get showPreviousPhoto =>
      _t('Show previous photo', 'Prikazi prethodnu fotografiju');

  // --- Charts ------------------------------------------------------

  String get notLogged => _t('not logged', 'nije upisano');
  String get logged => _t('logged', 'upisano');

  // --- Markers -----------------------------------------------------

  String get newMarker => _t('New marker', 'Novi marker');
  String get archivedHeading => _t('ARCHIVED', 'ARHIVIRANO');

  // --- Doctor page -------------------------------------------------

  String get pdfTitle => _t('Record summary', 'Pregled zabiljezenog');
  String pdfMade(String date) => _t('Made $date', 'Napravljeno $date');
  String pdfDays(int n) => _t('$n days', '$n dana');
  String pdfAnyEntry(int n) =>
      _t('at least one entry: $n days', 'bar jedan unos: $n dana');
  String get pdfPeriodStarts => _t('Period started', 'Pocetak menstruacije');
  String get pdfHowToReadTitle =>
      _t('How to read this page', 'Kako citati ovu stranicu');
  List<String> get pdfHowToRead => [
    _t(
      'Each marker has a chart: days run left to right, oldest on the '
          'left. A number is a line with a dot on each logged day; higher '
          'on the chart is a higher value.',
      'Svaki marker ima grafikon: dani idu s lijeva na desno, najstariji '
          'lijevo. Broj je linija sa tackom za svaki upisan dan; vise na '
          'grafikonu je veca vrijednost.',
    ),
    _t(
      'A break in the line is a day with no entry, which is not the same '
          'as zero. Yes/no: a tall bar is yes, a low tick is no.',
      'Prekid linije je dan bez unosa, sto nije isto sto i nula. Da/ne: '
          'visok stubic je da, nizak je ne.',
    ),
    _t(
      'Left of the chart: the typical value (median), the lowest and '
          'highest with their dates, and how many days were logged.',
      'Lijevo od grafikona: tipicna vrijednost (medijana), najniza i najvisa '
          'sa datumom, i koliko dana je upisano.',
    ),
    _t(
      'Comparison, if present: days split into groups by one marker, with '
          'the typical value of the other in each group and the day count.',
      'Poredjenje, ako postoji: dani podijeljeni u grupe po jednom '
          'markeru, sa tipicnom vrijednoscu drugog u svakoj grupi i brojem '
          'dana.',
    ),
  ];
  String get pdfFooter => _t(
    'Self-recorded. The numbers are what was entered, without '
        'interpretation. Typical = median of days with an entry. A gap in a '
        'chart = that day was not logged.',
    'Samostalno zabiljezeno. Brojevi su ono sto je upisano, bez tumacenja. '
        'Tipicno = medijana dana sa unosom. Prekid u grafikonu = taj dan '
        'nije upisan.',
  );
  String pdfCoverage(int logged, int total) =>
      _t('$logged/$total days logged', '$logged/$total dana upisano');
  String pdfYesDays(int yes, int logged) => _t(
    'yes: $yes of $logged logged days',
    'da: $yes od $logged upisanih dana',
  );
  String get pdfNothingPicked => _t('nothing picked', 'nista izabrano');
  String pdfMore(int n) => _t('+ $n more', '+ jos $n');
  String get lowest => _t('lowest', 'najnize');
  String get highest => _t('highest', 'najvise');
  String get doctorExplained => _t(
    'One page to print: numbers, ranges with dates and how many days were '
        'logged. No interpretation. The diary never goes on this page.',
    'Jedna stranica za stampu: brojevi, rasponi sa datumima i koliko je dana '
        'upisano. Bez tumacenja. Dnevnik nikad ne ide na ovu stranicu.',
  );
  String get paper => _t('Paper', 'Papir');
  String markersPicked(int n, int max) =>
      _t('Markers ($n/$max)', 'Markeri ($n/$max)');
  String get makePdf => _t('Make PDF', 'Napravi PDF');

  // --- Marker editor -----------------------------------------------

  String get marker => _t('Marker', 'Marker');
  String get markerNameHint => _t('bloating', 'nadutost');
  String get section => _t('Section', 'Sekcija');
  String get type => _t('Type', 'Tip');
  String get dayWithSeveralEntries =>
      _t('A day with several entries', 'Dan s vise unosa');
  String get howItIsDrawn => _t('How it is drawn', 'Kako se crta');
  String get colour => _t('Colour', 'Boja');
  String typeLocked(int count) => _t(
    'It already holds $count entries, so the type is locked. For another '
        'type: archive this one and make a new one.',
    'Vec ima $count unosa, pa je tip zakljucan. Za drugi tip: arhiviraj ovaj '
        'i napravi novi.',
  );
  String get range => _t('Range', 'Raspon');
  String get from => _t('from', 'od');
  String get to => _t('to', 'do');
  String get whatLowMeans => _t('What the lowest means', 'Sta znaci najniza');
  String get lowHint => _t('none', 'nista');
  String get whatHighMeans => _t('What the highest means', 'Sta znaci najvisa');
  String get highHint => _t('severe', 'jako');
  String get unit => _t('Unit', 'Jedinica');
  String get options => _t('Options', 'Opcije');
  String get option => _t('option', 'opcija');
  String get addOption => _t('Add option', 'Dodaj opciju');
  String get otherColour => _t('Another colour', 'Druga boja');
  String get putBackOnList => _t('Put back on the list', 'Vrati na listu');
  String get archiveVerb => _t('Archive', 'Arhiviraj');
  String get archivedExplained => _t(
    'An archived marker keeps every entry and stops being offered.',
    'Arhiviran marker zadrzava sve unose i vise se ne nudi.',
  );
  String get deleteMarker => _t('Delete marker', 'Obrisi marker');
  String get deleteMarkerQuestion => _t('Delete marker?', 'Obrisati marker?');
  String get deleteMarkerNoEntries =>
      _t('No entries, so nothing is lost.', 'Nema unosa, pa se nista ne gubi.');
  String deleteMarkerWithEntries(int count) => _t(
    'The entries stay recorded ($count), only the marker leaves the list. If '
        'you need it kept in reports, archive it instead.',
    'Unosi ostaju zapisani ($count), samo marker nestaje s liste. Ako ti '
        'treba da se cuva u izvjestajima, arhiviraj ga.',
  );
  String less(String label) => _t('$label down', '$label manje');
  String more(String label) => _t('$label up', '$label vise');
  String get restoreOption => _t('Restore option', 'Vrati opciju');
  String get archiveOption => _t('Archive option', 'Arhiviraj opciju');
  String get removeOption => _t('Remove option', 'Ukloni opciju');

  // --- Cycle -------------------------------------------------------

  String cycleDayNumber(int day) => _t('Day $day', 'Dan $day');
  String get cycleNotAnchored => _t('No cycle day', 'Nema dana ciklusa');
  String get cycleNothingRecorded => _t(
    'Nothing recorded yet. The first start is what everything else counts '
        'from.',
    'Jos nista nije upisano. Prvi pocetak je ono od cega se sve broji.',
  );
  String get cycleTooFarBack => _t(
    'The last start is too far back to count from.',
    'Posljednji pocetak je predaleko da bi se brojalo od njega.',
  );
  String cycleStartedOn(String date) => _t('started $date', 'pocelo $date');
  String cycleBleedingDays(int days) =>
      _t('$days days of bleeding', '$days dana krvarenja');
  String cycleBleedingSoFar(int days) =>
      _t('bleeding, day $days', 'krvarenje, $days. dan');
  String cycleLengthsLine(String lengths) =>
      _t('Cycles: $lengths', 'Ciklusi: $lengths');
  String get periodStarted => _t('Period started', 'Menstruacija pocela');
  String get periodEnded => _t('Period ended', 'Menstruacija stala');
  String get today => _t('Today', 'Danas');
  String get yesterday => _t('Yesterday', 'Juce');
  String get pickADate => _t('Pick a date', 'Odaberi datum');

  // --- Notes on a reading ------------------------------------------

  String get note => _t('Note', 'Biljeska');
  String get noteHint =>
      _t('anything worth remembering', 'sta god vrijedi zapamtiti');
  String notesHeldBack(int n) => _t(
    'Notes on readings left out: $n.',
    'Biljeske uz unose izostavljene: $n.',
  );

  // --- Profiles ----------------------------------------------------

  String get defaultProfileName => _t('Me', 'Ja');
  String get profiles => _t('Profiles', 'Profili');
  String get newProfile => _t('New profile', 'Novi profil');
  String get profileHeading => _t('PROFILE', 'PROFIL');
  String get startWith => _t('Start with', 'Pocni sa');
  String get startEmpty => _t('Empty', 'Prazno');
  String get startEmptyHint =>
      _t('No markers. You add your own.', 'Bez markera. Dodajes svoje.');
  String get startStarter => _t('Starter set', 'Osnovni set');
  String get startStarterHint => _t(
    'Mood, tiredness, sleep and the rest, without the cycle.',
    'Raspolozenje, umor, san i ostalo, bez ciklusa.',
  );
  String get startCopy => _t('Copy markers from', 'Kopiraj markere od');
  String get startCopyHint => _t(
    'Markers only. No entry is ever copied.',
    'Samo markeri. Nijedan unos se ne kopira.',
  );
  String get create => _t('Create', 'Napravi');
  String get rename => _t('Rename', 'Preimenuj');
  String get trackCycle => _t('Track the cycle', 'Prati ciklus');
  String get trackCycleHint => _t(
    'Off hides the cycle everywhere. Nothing recorded is deleted.',
    'Iskljuceno sakriva ciklus svuda. Nista upisano se ne brise.',
  );
  String get deleteProfile => _t('Delete profile', 'Obrisi profil');
  String deleteProfileQuestion(String name) =>
      _t('Delete $name?', 'Obrisati profil $name?');
  String get deleteProfileExplained => _t(
    'Its markers, entries, photos and reports disappear from the app. Other '
        'profiles are not touched.',
    'Njegovi markeri, unosi, fotografije i izvjestaji nestaju iz aplikacije. '
        'Ostali profili se ne diraju.',
  );
  String get lastProfile => _t(
    'The only profile cannot be deleted.',
    'Jedini profil se ne moze obrisati.',
  );

  // --- Deleting a profile ------------------------------------------

  String deleteNamedProfile(String name) =>
      _t('Delete profile "$name"', 'Obrisi profil "$name"');
  String typeNameToConfirm(String name) =>
      _t('Type "$name" to confirm.', 'Ukucaj "$name" da potvrdis.');

  // --- Settings headings -------------------------------------------

  String get languageHeading => _t('LANGUAGE', 'JEZIK');
  String get themeHeading => _t('THEME', 'TEMA');

  // --- Demo profile ------------------------------------------------

  String get demoProfile => _t('Demo profile', 'Demo profil');
  String get demoProfileHint => _t(
    'Four months of made-up data and a few reports, to see what reports can '
        'show. Your own profiles are not touched; delete it when done.',
    'Cetiri mjeseca izmisljenih podataka i nekoliko izvjestaja, da vidis sta '
        'izvjestaji mogu da pokazu. Tvoji profili se ne diraju; obrisi ga kad '
        'zavrsis.',
  );
  String get demoProfileName => _t('Demo', 'Demo');
  String get demoMoodAndTiredness =>
      _t('Mood and tiredness', 'Raspolozenje i umor');
  String get demoTrainingAndMood =>
      _t('Training and mood', 'Trening i raspolozenje');
  String get demoByCycleDay => _t('Through the cycle', 'Kroz ciklus');
  String get demoWeeklyRhythm => _t('Weekly rhythm', 'Nedjeljni ritam');
  String get makingDemo => _t('Making the demo...', 'Pravim demo...');

  // --- Welcome and tour ---------------------------------------------

  String get welcomeTitle =>
      _t('Welcome to Tideline', 'Dobro dosli u Tideline');
  String get welcomeBody => _t(
    'Track what matters to you - mood, sleep, symptoms, habits - and see '
        'what your days actually do.',
    'Prati ono sto ti je vazno - raspolozenje, san, simptome, navike - i '
        'vidi sta tvoji dani zaista rade.',
  );
  String get welcomeTour => _t('Show me around', 'Pokazi mi kako radi');
  String get welcomeTourHint => _t(
    'A short tour on a demo profile with made-up data.',
    'Kratak obilazak na demo profilu sa izmisljenim podacima.',
  );
  String get welcomeSkip =>
      _t('Skip, I will set it up myself', 'Preskoci, sama cu podesiti');

  String tourProgress(int step, int of) =>
      _t('TOUR  $step / $of', 'OBILAZAK  $step / $of');
  String get tourNext => _t('Next', 'Dalje');
  String get tourBack => _t('Back', 'Nazad');
  String get tourSkip => _t('Skip', 'Preskoci');
  String get tourFinish => _t('Set up my markers', 'Napravi moje markere');

  String get tourHomeTitle => _t('A demo profile', 'Demo profil');
  String get tourHomeBody => _t(
    'Four months of made-up entries. Each row is a marker: something you '
        'track. A tick means it is logged today, a dash means it is not.',
    'Cetiri mjeseca izmisljenih unosa. Svaki red je marker: nesto sto '
        'pratis. Kvacica znaci da je danas upisan, crtica da nije.',
  );
  String get tourLogTitle => _t('Logging', 'Upisivanje');
  String get tourLogBody => _t(
    'Tap a marker to log it: a rating, yes or no, tags, a time or a note. '
        'Try it now. Hold a marker to see its last month.',
    'Dodirni marker da ga upises: ocjena, da ili ne, oznake, vrijeme ili '
        'tekst. Probaj sada. Zadrzi prst na markeru da vidis njegov '
        'posljednji mjesec.',
  );
  String get tourDayTitle => _t('Every day', 'Svaki dan');
  String get tourDayBody => _t(
    'Each day has its own page with every entry, note and photo. The '
        'calendar icon on the home screen opens today.',
    'Svaki dan ima svoju stranicu sa svim unosima, biljeskama i '
        'fotografijama. Ikonica kalendara na pocetnoj otvara danasnji dan.',
  );
  String get tourReportsTitle => _t('Reports', 'Izvjestaji');
  String get tourReportsBody => _t(
    'Reports put markers side by side, so patterns show. The demo has four '
        'saved, + builds your own, and a one-page summary for a doctor is '
        'made from here too.',
    'Izvjestaji stavljaju markere jedan pored drugog, da se obrasci vide. '
        'Demo ima cetiri sacuvana, + pravi tvoj, a odavde se pravi i '
        'sazetak na jednoj stranici za doktora.',
  );
  String get tourLinesTitle => _t('Over time', 'Kroz vrijeme');
  String get tourLinesBody => _t(
    'Each marker is a row over the same days, so you can read them '
        'together: late bedtimes sit under the tired days. Tap a day to '
        'open it.',
    'Svaki marker je red preko istih dana, pa ih citas zajedno: kasni '
        'odlasci na spavanje stoje ispod umornih dana. Dodirni dan da ga '
        'otvoris.',
  );
  String get tourCycleTitle => _t('Through the cycle', 'Kroz ciklus');
  String get tourCycleBody => _t(
    'With the cycle on, a report can line days up by cycle day instead of '
        'date. Here bloating climbs in the last week of every cycle.',
    'Kad je ciklus ukljucen, izvjestaj moze poredati dane po danu ciklusa '
        'umjesto po datumu. Ovdje nadutost raste u posljednjoj sedmici '
        'svakog ciklusa.',
  );
  String get tourGridTitle => _t('Weekly rhythm', 'Nedjeljni ritam');
  String get tourGridBody => _t(
    'The grid lays the days out week by week. Look at the Sundays: mood '
        'drops on them almost every week.',
    'Mreza slaze dane sedmicu po sedmicu. Pogledaj nedjelje: raspolozenje '
        'tada pada skoro svake sedmice.',
  );
  String get tourMarkersTitle => _t('Your markers', 'Tvoji markeri');
  String get tourMarkersBody => _t(
    'Add, rename, recolour, reorder or archive any marker here. Nothing is '
        'built in: every marker is yours to change.',
    'Ovdje dodajes, preimenujes, mijenjas boju, redoslijed ili arhiviras '
        'bilo koji marker. Nista nije ugradjeno: svaki marker je tvoj.',
  );
  String get tourDoneTitle => _t('That is the tour', 'To je sve');
  String get tourDoneBody => _t(
    'Now pick what you want to track: start from suggestions or make your '
        'own.',
    'Sada izaberi sta zelis da pratis: kreni od predloga ili napravi '
        'svoje.',
  );

  String get tourEnd => _t('Back to my profile', 'Nazad na moj profil');
  String get tourReplayDoneBody => _t(
      'Leaving the tour takes you back to your own profile and removes the '
          'demo.',
      'Izlaskom iz obilaska vracas se na svoj profil, a demo se brise.');
  String get helpHeading => _t('HELP', 'POMOC');
  String get replayTour => _t('Take the tour again', 'Ponovi obilazak');
  String get replayTourHint => _t(
      'A walk through the app on a demo profile. Your own record is not '
          'touched.',
      'Obilazak aplikacije na demo profilu. Tvoji podaci se ne diraju.');

  // --- First setup ---------------------------------------------------

  String get setupTitle => _t('What will you track?', 'Sta ces pratiti?');
  String get setupIntro => _t(
    'Tick a few to start. Every marker can be renamed, changed or removed '
        'later.',
    'Oznaci nekoliko za pocetak. Svaki marker se kasnije moze '
        'preimenovati, promijeniti ili obrisati.',
  );
  String get setupCycle => _t('Track my cycle', 'Prati moj ciklus');
  String get setupCycleHint => _t(
    'Period start and end, so reports can line days up by cycle day.',
    'Pocetak i kraj menstruacije, da izvjestaji mogu poredati dane po danu '
        'ciklusa.',
  );
  String get setupKeepDemo => _t('Keep the demo profile', 'Zadrzi demo profil');
  String get setupKeepDemoHint => _t(
    'It stays in the profile menu, apart from your own record.',
    'Ostaje u meniju profila, odvojen od tvojih podataka.',
  );
  String get setupOwn => _t('Also make my own marker', 'Napravi i svoj marker');
  String get setupOwnHint => _t(
    'Opens the editor right after, for anything not on the list.',
    'Odmah zatim otvara editor, za sve sto nije na listi.',
  );
  String setupStart(int n) => n == 0
      ? _t('Start with nothing', 'Pocni bez markera')
      : _t('Start with $n', 'Pocni sa $n');
  String get setupDone => _t(
    'All set. The markers icon on the home screen changes them any time.',
    'Spremno. Ikonica markera na pocetnoj ih mijenja kad god hoces.',
  );

  // --- Themes ------------------------------------------------------

  String get modeSystem => _t('System', 'Sistem');
  String get modeLight => _t('Light', 'Svijetla');
  String get modeDark => _t('Dark', 'Tamna');

  // --- Report cards ------------------------------------------------

  String get daysLoggedLabel => _t('days logged', 'dana upisano');

  // --- Report cards 2 ----------------------------------------------

  String get rangeLower => _t('range', 'raspon');

  // --- Comparing two markers ---------------------------------------

  String get compareHeading => _t('Compare', 'Poredjenje');
  String get compareOff => _t('Off', 'Iskljuceno');
  String get compareSameDay => _t('Same day', 'Isti dan');
  String get compareNextDay => _t('Next day', 'Sljedeci dan');
  String get compareExplained => _t(
    'Splits the days by the first marker and reads the second on them. Pick '
        'the condition first.',
    'Dijeli dane po prvom markeru i cita drugi na njima. Prvo izaberi uslov.',
  );
  String compareTitle(String outcome, String condition) =>
      _t('$outcome by $condition', '$outcome po: $condition');
  String get compareNextDayNote =>
      _t('Read on the day after.', 'Cita se dan poslije.');
  String comparePairedDays(int days) =>
      _t('$days days with both', '$days dana sa oba');
  String get compareYes => _t('yes', 'da');
  String get compareNo => _t('no', 'ne');
  String get compareHigh => _t('highest third', 'najvisa trecina');
  String get compareLow => _t('lowest third', 'najniza trecina');
  String get compareTooLittle => _t(
    'Not enough days where both were logged.',
    'Premalo dana gdje su oba upisana.',
  );
  String get compareNoClaim => _t(
    'Counted days, side by side. The app makes no claim about why.',
    'Prebrojani dani, jedno uz drugo. Aplikacija ne tvrdi zasto.',
  );

  // --- Dependency chart --------------------------------------------

  String get compareHowToRead => _t('How to read this', 'Kako ovo citati');

  /// Over time, in words, with both marker names filled in.
  String compareReadTimeline(String condition, String outcome) => _t(
    'The top line is $condition, the bottom one is $outcome. The same day '
        'sits straight under itself, so read them column by column: when '
        '$condition goes up, look at what $outcome does right below it. '
        'Each line has its own scale, so compare the ups and downs, not the '
        'heights. For a yes/no marker the top row is marks instead: filled = '
        'yes, outline = no, nothing = not logged. A dashed stretch is days '
        'not logged.',
    'Gornja linija je $condition, donja je $outcome. Isti dan stoji tacno '
        'jedan ispod drugog, pa citaj kolonu po kolonu: kad $condition '
        'poraste, pogledaj sta $outcome radi odmah ispod. Svaka linija ima '
        'svoju skalu, zato poredi rast i pad, ne visinu. Za da/ne marker '
        'gornji red su kvadratici: pun = da, prazan okvir = ne, nista = nije '
        'uneseno. Isprekidan dio su dani bez unosa.',
  );

  /// The dependency view for a yes/no or tags condition: columns of dots.
  String compareReadGroups(String condition, String outcome) => _t(
    'Each dot is one day where both were logged. The days are split into '
        'columns by $condition (for example "yes" and "no"). How high a dot '
        'sits is $outcome that day. The dark dash in each column is the '
        'typical $outcome for those days, and it is the number in the list '
        'below. If the "yes" dash sits clearly higher than the "no" dash, '
        '$outcome was higher on days with $condition. Check the day count '
        'next to it: a handful of days says little.',
    'Svaka tacka je jedan dan kad su oba unesena. Dani su podijeljeni u '
        'kolone po tome sta je bilo sa $condition (npr. "da" i "ne"). Visina '
        'tacke je $outcome tog dana. Tamna crtica u koloni je tipican '
        '$outcome za te dane, i to je broj u listi ispod. Ako je crtica kod '
        '"da" jasno visa nego kod "ne", $outcome je bio veci u danima sa '
        '$condition. Pogledaj i broj dana pored: par dana malo govori.',
  );

  /// The dependency view for a number condition: a scatter.
  String compareReadScatter(String condition, String outcome) => _t(
    'Each dot is one day where both were logged. Left to right is how much '
        '$condition there was that day, bottom to top is $outcome. If the '
        'dots climb towards the right, $outcome was higher on days with more '
        '$condition. If they fall, it was lower. If they are scattered with '
        'no direction, the two did not move together. The list below splits '
        'the days into the lowest and highest third of $condition and gives '
        'the typical $outcome for each.',
    'Svaka tacka je jedan dan kad su oba unesena. Slijeva nadesno je koliko '
        'je $condition bilo tog dana, odozdo nagore je $outcome. Ako se '
        'tacke penju prema desno, $outcome je bio veci u danima sa vise '
        '$condition. Ako se spustaju, bio je manji. Ako su razbacane bez '
        'smjera, njih dvoje se nisu mijenjali zajedno. Lista ispod dijeli '
        'dane na najnizu i najvisu trecinu $condition i daje tipican '
        '$outcome za svaku.',
  );

  String get compareOverTime => _t('Over time', 'Kroz vrijeme');
  String get compareDependency => _t('Dependency', 'Zavisnost');
  String get compareTimelineHint => _t(
    'One line per marker, each on its own scale. A dashed stretch is days '
        'not logged.',
    'Jedna linija po markeru, svaka na svojoj skali. Isprekidan dio su dani '
        'bez unosa.',
  );

  String get compareChartHint => _t(
    'One dot per day. No line is fitted through them.',
    'Jedna tacka po danu. Kroz njih se ne provlaci nikakva linija.',
  );

  // --- Sharing one report ------------------------------------------

  String get shareThisReport =>
      _t('Share this report', 'Podijeli ovaj izvjestaj');
  String get shareForAi => _t('For AI (text)', 'Za AI (tekst)');
  String get shareForAiHint => _t(
    'The markers of this report, its period, and the readings as JSON.',
    'Markeri ovog izvjestaja, njegov period i unosi kao JSON.',
  );
  String get shareCsv => _t('Spreadsheet (CSV)', 'Tabela (CSV)');
  String get shareCsvHint => _t(
    'One row per reading, for a spreadsheet.',
    'Jedan red po unosu, za tabelu.',
  );
  String get shareDoctor =>
      _t('Doctor page (PDF)', 'Stranica za doktora (PDF)');
  String get shareDoctorHint => _t(
    'One printable page: numbers, ranges with dates, days logged.',
    'Jedna stranica za stampu: brojevi, rasponi sa datumima, upisani dani.',
  );
  String get shareDiaryIncluded =>
      _t('Include diary and notes', 'Ukljuci dnevnik i biljeske');
  String get sharePreparing => _t('Preparing...', 'Pripremam...');

  // --- Photos on any entry -----------------------------------------

  String get addPhoto => _t('Photo', 'Slika');
  String get photoAdded => _t('Photo added', 'Slika dodata');
  String markedDaysLine(int notes, int photos) => _t(
    '$notes with a note, $photos with a photo',
    '$notes sa biljeskom, $photos sa slikom',
  );
}
