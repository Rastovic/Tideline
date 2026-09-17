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
        MetricKind.scale => _t('A slider between two ends you set',
            'Klizac izmedju dvije granice koje sama postavis'),
        MetricKind.percent =>
          _t('0 to 100, in steps of five', '0 do 100, u koracima od pet'),
        MetricKind.count => _t('How many times. Glasses of water, cigarettes',
            'Koliko puta. Case vode, cigarete'),
        MetricKind.duration => _t('Hours and minutes', 'Sati i minute'),
        MetricKind.amount =>
          _t('A number with a unit. Dose, weight', 'Broj s jedinicom. Doza, tezina'),
        MetricKind.boolean => _t('It happened or it did not', 'Bilo je ili nije bilo'),
        MetricKind.choice => _t('Exactly one option from your list',
            'Tacno jedna opcija s tvoje liste'),
        MetricKind.tags =>
          _t('Any number of options from your list', 'Koliko god opcija s tvoje liste'),
        MetricKind.text => _t('Free text. A diary', 'Slobodan tekst. Dnevnik'),
        MetricKind.photo => _t('A photo with a caption', 'Slika s opisom'),
        MetricKind.timeOfDay =>
          _t('A time of day. Bedtime, waking up', 'Sat u danu. Lijeganje, ustajanje'),
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
        DayAggregation.sum =>
          _t('3 g and 2 g on the same day make 5 g', '3 g i 2 g istog dana su 5 g'),
        DayAggregation.typical => _t('The median, not the mean', 'Medijana, ne prosjek'),
        DayAggregation.peak =>
          _t('The peak of the day. For bloating and pain', 'Vrhunac dana. Za nadutost i bol'),
        DayAggregation.lowest => _t('The lowest value of the day', 'Najniza vrijednost dana'),
        DayAggregation.last => _t('The latest entry by time', 'Posljednji unos po vremenu'),
        DayAggregation.anyTrue => _t('The day counts if it happened even once',
            'Dan se broji ako je bilo makar jednom'),
        DayAggregation.union =>
          _t('Everything marked that day', 'Sve sto je taj dan oznaceno'),
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
      ? const ['January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December']
      : const ['januar', 'februar', 'mart', 'april', 'maj', 'jun', 'jul',
          'avgust', 'septembar', 'oktobar', 'novembar', 'decembar'];

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

  String get captureUnavailable =>
      _t('Taking a photo is not available here.', 'Slikanje nije dostupno ovdje.');
  String get takePhoto => _t('Take photo', 'Slikaj');
  String get fromGallery => _t('From gallery', 'Iz galerije');
  String get photosStayInApp => _t('Photos stay in the app, never in the gallery.',
      'Fotografije ostaju u aplikaciji, nikad u galeriji.');
  String get didNotHappen => _t('It did not', 'Nije bilo');
  String get happened => _t('It did', 'Bilo je');
  String get noneOfTheseButton => _t('None of these', 'Nista od ovoga');
  String get noneOfThese => _t('none of these', 'nista od ovoga');
  String get diaryHint => _t('How it went, and why', 'Kako je bilo, i zbog cega');
  String get private => _t('Private', 'Privatno');
  String get privateLower => _t('private', 'privatno');
  String get privateExplained => _t('Never shown in search or on the doctor page',
      'Ne pojavljuje se u pretrazi ni na stranici za doktora');
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
  String get deletePhotoQuestion => _t('Delete photo?', 'Obrisati fotografiju?');
  String get deletePhotoExplained => _t(
      'The file is deleted from the phone. This cannot be undone.',
      'Fajl se brise sa telefona. Ovo se ne vraca.');
  String get caption => _t('Caption', 'Opis');
  String get captionHint => _t('e.g. after training', 'npr. poslije treninga');
  String get noPhotosYet => _t('No photos yet.', 'Jos nema fotografija.');
  String get searchHint =>
      _t('Search the diary and photo captions', 'Pretrazi dnevnik i opise fotografija');
  String get includePrivate => _t('Include private', 'Ukljuci privatne');
  String get nothingFound =>
      _t('Nothing contains those words.', 'Nista ne sadrzi te rijeci.');

  // --- Reports and export ------------------------------------------

  String get deleteReportQuestion => _t('Delete report?', 'Obrisati izvjestaj?');
  String get deleteReportExplained => _t(
      'No entry is touched. A report is only a question asked of the data.',
      'Nijedan unos se ne dira. Izvjestaj je samo pitanje nad podacima.');
  String get export => _t('Export', 'Izvoz');
  String get doctorPage => _t('Doctor page', 'Stranica za doktora');
  String get newReport => _t('New report', 'Novi izvjestaj');
  String get report => _t('Report', 'Izvjestaj');
  String get noReportsYet => _t(
      'None yet. A report is a set of markers and a period - rows stacked on '
          'one time axis, so you can read them side by side.',
      'Jos nijedan. Izvjestaj je set markera i period - slozeni redovi na '
          'istoj vremenskoj osi, da ih citas jedan uz drugi.');
  String window(int days) => switch (days) {
        7 => _t('7 days', '7 dana'),
        30 => _t('month', 'mjesec'),
        90 => _t('3 months', '3 mjeseca'),
        180 => _t('6 months', '6 mjeseci'),
        365 => _t('year', 'godina'),
        _ => _t('$days days', '$days dana'),
      };
  String get all => _t('all', 'sve');
  String markerCount(int n) => _t(n == 1 ? '1 marker' : '$n markers', '$n markera');
  String get edit => _t('Edit', 'Izmijeni');
  String get saveAsReport => _t('Save as report', 'Sacuvaj kao izvjestaj');
  String get reportMarkersGone => _t(
      'None of the markers in this report exist any more.',
      'Nijedan marker u ovom izvjestaju vise ne postoji.');
  String get byDate => _t('By date', 'Po datumu');
  String get byCycleDay => _t('By cycle day', 'Po danu ciklusa');
  String get grid => _t('Grid', 'Mreza');
  String behind(String name) => _t('behind: $name', 'iza: $name');
  String get typical => _t('typical', 'tipicno');
  String get weekly => _t('weekly', 'tjedno');
  String daysOf(int logged, int total) => _t('$logged/$total days', '$logged/$total dana');
  String get dateRange => _t('Date range', 'Raspon datuma');
  String get use => _t('Use', 'Uzmi');
  String get nameTheReport => _t('Give the report a name.', 'Daj izvjestaju ime.');
  String get pickAtLeastOneMarker =>
      _t('Pick at least one marker.', 'Izaberi bar jedan marker.');
  String get name => _t('Name', 'Ime');
  String get reportNameHint => _t('creatine and bloating', 'kreatin i nadutost');
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
  String privateHeldBack(int n) => _t('Private diary entries left out: $n.',
      'Privatni unosi dnevnika izostavljeni: $n.');
  String diaryHeldBack(int n) => _t('Diary not ticked, left out: $n.',
      'Dnevnik nije izabran, izostavljeno: $n.');
  String get shareFile => _t('Share file', 'Podijeli fajl');

  // --- Backup ------------------------------------------------------

  String get archive => _t('Backup', 'Arhiva');
  String get archiveReady => _t('Backup is ready', 'Arhiva je spremna');
  String get share => _t('Share', 'Podijeli');
  String get archiveNotSent => _t('The backup was not sent anywhere.', 'Arhiva nije nigdje poslana.');
  String get nothingLoaded => _t('Nothing was loaded.', 'Nista nije ucitano.');
  String get nothingChanged => _t('Nothing was changed.', 'Nista nije promijenjeno.');
  String get restoreQuestion => _t('Restore this backup?', 'Vratiti ovu arhivu?');
  String get restore => _t('Restore', 'Vrati');
  String get archiveExplained => _t(
      'One file with everything: markers, entries, reports and photos. The '
          'photos are inside, not next to it - a backup that quietly leaves out '
          'half of what you would miss is not a backup.',
      'Jedan fajl sa svime: markeri, unosi, izvjestaji i fotografije. '
          'Fotografije su unutra, ne pored - arhiva koja tiho izostavi pola '
          'onoga za cim bi zalila nije arhiva.');
  String get makeArchive => _t('Make a backup', 'Napravi arhivu');
  String get restoreFromArchive => _t('Restore from backup', 'Vrati iz arhive');
  String get restoreExplained => _t(
      'Restoring replaces everything now in the app. It shows you what is in '
          'the file first.',
      'Vracanje zamjenjuje sve sto je sada u aplikaciji. Prvo ti pokaze sta je '
          'u fajlu.');
  String get refusedMalformed => _t(
      'This is not a backup from this app. Nothing was changed.',
      'Ovo nije arhiva ove aplikacije. Nista nije promijenjeno.');
  String get refusedFuture => _t(
      'This backup was made by a newer version of the app. Nothing was '
          'written - half an import would be worse than none.',
      'Ova arhiva je napravljena novijom verzijom aplikacije. Nista nije '
          'upisano - pola uvoza bi bilo gore od nijednog.');
  String get refusedDamaged => _t(
      'The file is damaged, so it cannot be trusted. Nothing was changed.',
      'Fajl je ostecen, pa mu se ne moze vjerovati. Nista nije promijenjeno.');
  String get refusedIncomplete => _t(
      'Part of the backup is missing. It may not have finished saving. '
          'Nothing was changed.',
      'Arhivi nedostaje dio. Mozda se nije do kraja sacuvala. Nista nije '
          'promijenjeno.');
  String photoCount(int n) => _t(n == 1 ? '1 photo' : '$n photos', '$n fotografija');
  String photosWithoutFile(int n) => _t(
      '$n photos have no file on disk and are not in the backup.',
      '$n fotografija nema fajl na disku i nije usla u arhivu.');
  String dayRange(String from, String to) => _t('$from to $to', '$from do $to');
  String entriesAndPhotos(int entries, int photos) =>
      _t('$entries entries and $photos photos', '$entries unosa i $photos fotografija');
  String get replacesEverything => _t(
      'This replaces everything now in the app.',
      'Ovo zamjenjuje sve sto je sada u aplikaciji.');
  String restored(int rows, int photos) => _t(
      '$rows rows restored, $photos photos.',
      '$rows redova vraceno, $photos fotografija.');
  String photosNotInArchive(int n) => _t(
      '$n photos were not in the backup - the days and captions are here, the '
          'images are not.',
      '$n fotografija nije bilo u arhivi - dani i opisi su tu, same slike nisu.');

  // --- Settings ----------------------------------------------------

  String get reminderHeading => _t('REMINDER', 'PODSJETNIK');
  String get oneEveningReminder => _t('One evening reminder', 'Jedan podsjetnik uvece');
  String get time => _t('Time', 'Vrijeme');
  String get reminderPromise => _t(
      'It says the same thing every evening and opens the marker list. It does '
          'not know whether you logged anything and never mentions a missed day.',
      'Kaze isto svake veceri i otvara listu markera. Ne zna da li si nesto '
          'upisala i ne spominje propusteni dan.');
  String get reminderBody => _t('Write down how it went.', 'Upisi kako je bilo.');
  String get lockHeading => _t('LOCK', 'ZAKLJUCAVANJE');
  String get lockTitle => _t('Fingerprint or phone PIN', 'Otisak ili PIN telefona');
  String get lockExplained => _t(
      'On opening and after a minute away. Turning it off needs an unlock.',
      'Pri otvaranju i nakon minute van aplikacije. Za iskljucivanje treba '
          'otkljucati.');
  String get lockUnavailable => _t(
      'The phone has no screen lock, so the app cannot be locked.',
      'Telefon nema zakljucan ekran, pa aplikacija ne moze biti zakljucana.');
  String get unlockReason => _t('Unlock Tideline', 'Otkljucaj Tideline');
  String get locked => _t('Tideline is locked', 'Tideline je zakljucan');
  String get unlock => _t('Unlock', 'Otkljucaj');
  String get widgetHeading => _t('HOME SCREEN WIDGET', 'WIDGET NA POCETNOM EKRANU');
  String widgetExplained(int slots) => _t(
      'Up to $slots markers. The widget shows names only, never values or '
          'whether anything was logged.',
      'Do $slots markera. Widget prikazuje samo imena, nikad vrijednosti ni da '
          'li je nesto upisano.');
  String get widgetEmpty =>
      _t('Pick markers in Settings', 'Izaberi markere u Podesavanjima');
  String get dayHeading => _t('DAY', 'DAN');
  String get newDayStartsAt => _t('A new day starts at', 'Novi dan pocinje u');
  String get dayBoundaryExplained => _t(
      'An entry at 01:30 belongs to the day that just ended. A change applies '
          'to new entries; old ones stay where they are.',
      'Unos u 01:30 pripada danu koji se upravo zavrsio. Promjena vazi za nove '
          'unose; stari ostaju gdje su.');
  String get archiveHeading => _t('BACKUP', 'ARHIVA');
  String get photosTakeUp => _t('Photos take up', 'Fotografije zauzimaju');
  String get backupAndRestore => _t('Backup and restore', 'Backup i vracanje');
  String get oneFileWithEverything =>
      _t('One file with everything, photos inside', 'Jedan fajl sa svime, fotografije unutra');
  String get notificationsBlocked => _t(
      'Notifications are turned off in the phone settings, so the reminder '
          'cannot arrive. Everything else works normally.',
      'Obavjestenja su iskljucena u postavkama telefona, pa podsjetnik ne moze '
          'stici. Sve ostalo radi normalno.');

  // --- Camera ------------------------------------------------------

  String get noCamera => _t('The phone has no camera.', 'Telefon nema kameru.');
  String get cameraNotAllowed => _t(
      'The camera is not allowed. Permission is given in the phone settings.',
      'Kamera nije dozvoljena. Dozvola se daje u postavkama telefona.');
  String get cameraFailed => _t('The camera could not be opened.', 'Kamera se nije mogla otvoriti.');
  String get hidePreviousPhoto => _t('Hide previous photo', 'Sakrij prethodnu fotografiju');
  String get showPreviousPhoto => _t('Show previous photo', 'Prikazi prethodnu fotografiju');

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
  String get pdfFooter => _t(
      'Self-recorded. The numbers are what was entered, without '
          'interpretation. Typical = median of days with an entry. Empty square '
          '= that day was not logged.',
      'Samostalno zabiljezeno. Brojevi su ono sto je upisano, bez tumacenja. '
          'Tipicno = medijana dana sa unosom. Prazan kvadrat = taj dan nije '
          'upisan.');
  String pdfCoverage(int logged, int total) =>
      _t('$logged/$total days logged', '$logged/$total dana upisano');
  String pdfYesDays(int yes, int logged) =>
      _t('yes: $yes of $logged logged days', 'da: $yes od $logged upisanih dana');
  String get pdfNothingPicked => _t('nothing picked', 'nista izabrano');
  String pdfMore(int n) => _t('+ $n more', '+ jos $n');
  String get lowest => _t('lowest', 'najnize');
  String get highest => _t('highest', 'najvise');
  String get doctorExplained => _t(
      'One page to print: numbers, ranges with dates and how many days were '
          'logged. No interpretation. The diary never goes on this page.',
      'Jedna stranica za stampu: brojevi, rasponi sa datumima i koliko je dana '
          'upisano. Bez tumacenja. Dnevnik nikad ne ide na ovu stranicu.');
  String get paper => _t('Paper', 'Papir');
  String markersPicked(int n, int max) => _t('Markers ($n/$max)', 'Markeri ($n/$max)');
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
          'i napravi novi.');
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
      'Arhiviran marker zadrzava sve unose i vise se ne nudi.');
  String get deleteMarker => _t('Delete marker', 'Obrisi marker');
  String get deleteMarkerQuestion => _t('Delete marker?', 'Obrisati marker?');
  String get deleteMarkerNoEntries =>
      _t('No entries, so nothing is lost.', 'Nema unosa, pa se nista ne gubi.');
  String deleteMarkerWithEntries(int count) => _t(
      'The entries stay recorded ($count), only the marker leaves the list. If '
          'you need it kept in reports, archive it instead.',
      'Unosi ostaju zapisani ($count), samo marker nestaje s liste. Ako ti '
          'treba da se cuva u izvjestajima, arhiviraj ga.');
  String less(String label) => _t('$label down', '$label manje');
  String more(String label) => _t('$label up', '$label vise');
  String get restoreOption => _t('Restore option', 'Vrati opciju');
  String get archiveOption => _t('Archive option', 'Arhiviraj opciju');
  String get removeOption => _t('Remove option', 'Ukloni opciju');
}
