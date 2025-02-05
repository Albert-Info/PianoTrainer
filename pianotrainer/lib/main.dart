import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Für plattformübergreifende Checks

void main() => runApp(MyApp());

/// Unterscheidung der Übungsmodi: Einzelnoten vs. Sequenz (10 Noten)
enum PracticeMode { individual, sequence }

/// Unterscheidung der Schlüsseltypen: Violinschlüssel (Treble) oder Bassschlüssel (Bass)
enum ClefType { treble, bass }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noten lernen für Klavier',
      home: NoteLearningApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NoteLearningApp extends StatefulWidget {
  @override
  _NoteLearningAppState createState() => _NoteLearningAppState();
}

class _NoteLearningAppState extends State<NoteLearningApp> {
  // Standardmäßig im Einzelnoten-Modus starten.
  PracticeMode _mode = PracticeMode.individual;
  // Standardmäßig den Violinschlüssel wählen.
  ClefType _selectedClef = ClefType.treble;

  // Variable zum Ein-/Ausschalten der Notenbeschriftung auf dem Klavier.
  bool _showKeyLabels = true;

  // Listen für die zu übenden Noten (je nach Clef)
  final List<String> _trebleNotes = [];
  final List<String> _bassNotes = [];

  // Einzelnoten-Modus:
  String _currentNote = '';
  // Sequenz-Modus: Hier werden 10 Noten in Folge generiert.
  List<String> _sequence = [];
  int _currentIndex = 0;

  // Letzte gedrückte Taste (für das Highlighting) und deren Ergebnis:
  String? _lastTappedNote;
  bool? _lastTapCorrect;
  // Sperrt Eingaben während der Highlight-Phase.
  bool _inputLocked = false;

  @override
  void initState() {
    super.initState();
    // Erzeuge Notenliste für den Violinschlüssel: Hier verwenden wir Noten von C4 bis B5 plus C6.
    for (var octave in [4, 5]) {
      for (var note in [
        'C',
        'C#',
        'D',
        'D#',
        'E',
        'F',
        'F#',
        'G',
        'G#',
        'A',
        'A#',
        'B'
      ]) {
        _trebleNotes.add('$note$octave');
      }
    }
    _trebleNotes.add('C6'); // oberstes C

    // Erzeuge Notenliste für den Bassschlüssel: Beispielbereich von F2 bis B3 plus C4.
    for (var octave in [2, 3]) {
      for (var note in ['F', 'F#', 'G', 'G#', 'A', 'A#', 'B']) {
        _bassNotes.add('$note$octave');
      }
    }
    _bassNotes.add('C4'); // als obere Grenze

    _resetPractice();
  }

  /// Setzt den Zustand zurück (beim Modi-Wechsel, Clef-Wechsel oder per Button)
  void _resetPractice() {
    _lastTappedNote = null;
    _lastTapCorrect = null;
    _inputLocked = false;
    if (_mode == PracticeMode.individual) {
      _pickRandomNote();
    } else {
      _generateSequence();
      _currentIndex = 0;
    }
  }

  /// Wählt im Einzelnoten-Modus zufällig eine Note aus dem entsprechenden Notenbereich.
  void _pickRandomNote() {
    setState(() {
      List<String> pool =
          _selectedClef == ClefType.treble ? _trebleNotes : _bassNotes;
      _currentNote = pool[Random().nextInt(pool.length)];
    });
  }

  /// Erzeugt im Sequenz-Modus eine Liste mit 10 zufälligen Noten aus dem entsprechenden Notenbereich.
  void _generateSequence() {
    final random = Random();
    List<String> pool =
        _selectedClef == ClefType.treble ? _trebleNotes : _bassNotes;
    _sequence = List.generate(10, (_) => pool[random.nextInt(pool.length)]);
    setState(() {});
  }

  /// Liefert die aktuell erwartete Note, je nach Modus.
  String get _currentExpectedNote {
    return _mode == PracticeMode.individual
        ? _currentNote
        : _sequence[_currentIndex];
  }

  /// Wird aufgerufen, wenn eine Klaviertaste gedrückt wird.
  void _onKeyTap(String tappedNote) {
    if (_inputLocked) return;

    setState(() {
      _lastTappedNote = tappedNote;
      _lastTapCorrect = (tappedNote == _currentExpectedNote);
      _inputLocked = true;
    });

    if (tappedNote == _currentExpectedNote) {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _lastTappedNote = null;
          _lastTapCorrect = null;
          _inputLocked = false;
          if (_mode == PracticeMode.individual) {
            _pickRandomNote();
          } else {
            _advanceSequence();
          }
        });
      });
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _lastTappedNote = null;
          _lastTapCorrect = null;
          _inputLocked = false;
        });
      });
    }
  }

  /// Im Sequenz-Modus: Gehe zur nächsten Note.
  void _advanceSequence() {
    if (_currentIndex < _sequence.length - 1) {
      _currentIndex++;
    } else {
      _generateSequence();
      _currentIndex = 0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Noten lernen für Klavier'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            // Auswahl der Modi (Einzelnoten / Sequenz)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _mode = PracticeMode.individual;
                      _resetPractice();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mode == PracticeMode.individual
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: Text("Einzelnoten"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _mode = PracticeMode.sequence;
                      _resetPractice();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mode == PracticeMode.sequence
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: Text("Sequenz (10 Noten)"),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Auswahl des Schlüssels: Violinschlüssel oder Bassschlüssel.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedClef = ClefType.treble;
                      _resetPractice();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedClef == ClefType.treble
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: Text("Violinschlüssel"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedClef = ClefType.bass;
                      _resetPractice();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedClef == ClefType.bass
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  child: Text("Bassschlüssel"),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Checkbox zum Ein-/Ausschalten der Notenbeschriftung auf dem Klavier.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _showKeyLabels,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _showKeyLabels = newValue ?? true;
                    });
                  },
                ),
                Text("Notenbeschriftung anzeigen")
              ],
            ),
            SizedBox(height: 10),
            Text(
              _mode == PracticeMode.individual
                  ? 'Erkenne die Note:'
                  : 'Spiele die Sequenz – Note für Note:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            // Notensystem: Je nach Modus wird entweder eine einzelne Note oder die ganze Sequenz gezeichnet.
            SizedBox(
              height: 220,
              child: CustomPaint(
                size: Size(double.infinity, 220),
                painter: _mode == PracticeMode.individual
                    ? StaffPainter(_currentExpectedNote, clef: _selectedClef)
                    : SequenceStaffPainter(_sequence, _currentIndex,
                        clef: _selectedClef),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Spiele die Note auf dem Flügel:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            // Vollständiger Flügel: Eine horizontal scrollbare Klaviertastatur (88 Tasten).
            Container(
              height: 150,
              child: FullPianoKeyboard(
                onKeyTap: _onKeyTap,
                lastTappedNote: _lastTappedNote,
                lastTapCorrect: _lastTapCorrect,
                showKeyLabels: _showKeyLabels,
              ),
            ),
            SizedBox(height: 10),
            // Button zum Generieren einer neuen Sequenz bzw. einer neuen Note.
            _mode == PracticeMode.sequence
                ? ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _generateSequence();
                        _currentIndex = 0;
                      });
                    },
                    child: Text("Neue Sequenz generieren"),
                  )
                : ElevatedButton(
                    onPressed: _pickRandomNote,
                    child: Text("Neue Note"),
                  ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Berechnet einen diatonischen Wert zur Positionierung im Notensystem.
/// Dabei wird nur der Buchstabe (A–G) und die Oktave berücksichtigt.
/// Es gilt: C=0, D=1, …, B=6.
int getDiatonicValue(String note) {
  String letter = note[0];
  bool isSharp = note.length > 2 && note[1] == '#';
  int octave = int.parse(note.substring(isSharp ? 2 : 1));
  Map<String, int> letterValues = {
    'C': 0,
    'D': 1,
    'E': 2,
    'F': 3,
    'G': 4,
    'A': 5,
    'B': 6,
  };
  return octave * 7 + letterValues[letter]!;
}

/// Zeichnet ein Notensystem (Staff) für einen einzelnen Notehead.
/// Zusätzlich wird der gewählte Schlüssel (Violinschlüssel oder Bassschlüssel) links dargestellt.
/// - Für Violinschlüssel: untere Linie entspricht E4 (Wert 30).
/// - Für Bassschlüssel: untere Linie entspricht G2 (Wert 18).
class StaffPainter extends CustomPainter {
  final String note;
  final ClefType clef;
  StaffPainter(this.note, {required this.clef});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    const double step = 10.0;
    const double leftMargin = 20.0;
    const double rightMargin = 20.0;
    double baseY = 150.0;
    int baseRef = clef == ClefType.treble ? 30 : 18;

    // Zeichne die fünf Linien des Notensystems.
    for (int i = 0; i <= 8; i += 2) {
      double y = baseY - i * step;
      canvas.drawLine(Offset(leftMargin, y),
          Offset(size.width - rightMargin, y), linePaint);
    }

    // Zeichne den Schlüssel (Clef) links.
    _drawClef(canvas, size);

    if (note.isNotEmpty) {
      int offset = getDiatonicValue(note) - baseRef;
      double noteY = baseY - offset * step;
      double noteX = size.width / 2;

      // Zeichne Ledger Lines falls nötig.
      if ((offset < 0 || offset > 8) && offset % 2 == 0) {
        canvas.drawLine(
            Offset(noteX - 20, noteY), Offset(noteX + 20, noteY), linePaint);
      }

      // Zeichne den Notehead.
      final notePaint = Paint()..color = Colors.black;
      Rect noteRect =
          Rect.fromCenter(center: Offset(noteX, noteY), width: 16, height: 10);
      canvas.drawOval(noteRect, notePaint);

      // Zeichne ggf. das ♯-Symbol.
      if (note.contains('#')) {
        final textSpan = TextSpan(
            text: '♯', style: TextStyle(color: Colors.black, fontSize: 16));
        final tp =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(noteX - 30, noteY - tp.height / 2));
      }
    }
  }

  void _drawClef(Canvas canvas, Size size) {
    // Verwende Unicode-Symbole für den Clef.
    // Für den Violinschlüssel verwenden wir "𝄞" (U+1D11E), für den Bassschlüssel "𝄢" (U+1D122).
    final String clefSymbol =
        clef == ClefType.treble ? "\u{1D11E}" : "\u{1D122}";
    final textSpan = TextSpan(
      text: clefSymbol,
      style: TextStyle(color: Colors.black, fontSize: 80),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    // Positioniere den Clef nahe der linken Kante.
    double x = 0;
    // Zentriere vertikal relativ zur Basislinie (hier ca. baseY - half the clef height).
    double y = 150 - tp.height / 2 - 40;
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.note != note || oldDelegate.clef != clef;
  }
}

/// Zeichnet ein Notensystem, in dem eine ganze Sequenz von Noten horizontal verteilt wird.
/// Jede Note wird anhand ihres diatonischen Werts positioniert; die aktuell zu spielende Note
/// wird hervorgehoben (gelb), bereits korrekt gespielte Noten erscheinen hellgrün.
/// Auch hier wird der Clef (Schlüssel) links gezeichnet.
class SequenceStaffPainter extends CustomPainter {
  final List<String> sequence;
  final int currentIndex;
  final ClefType clef;
  SequenceStaffPainter(this.sequence, this.currentIndex, {required this.clef});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    const double step = 10.0;
    const double baseY = 150.0;
    const double leftMargin = 20.0;
    const double rightMargin = 20.0;
    final double availableWidth = size.width - leftMargin - rightMargin;
    int noteCount = sequence.length;
    double spacing = noteCount > 1 ? availableWidth / (noteCount - 1) : 0;
    int baseRef = clef == ClefType.treble ? 30 : 18;

    // Zeichne die fünf Linien.
    for (int i = 0; i <= 8; i += 2) {
      double y = baseY - i * step;
      canvas.drawLine(Offset(leftMargin, y),
          Offset(size.width - rightMargin, y), linePaint);
    }

    // Zeichne den Clef links.
    _drawClef(canvas, size);

    // Zeichne jede Note der Sequenz.
    for (int i = 0; i < noteCount; i++) {
      String note = sequence[i];
      double x = leftMargin + i * spacing;
      int offset = getDiatonicValue(note) - baseRef;
      double noteY = baseY - offset * step;

      Color noteColor;
      if (i < currentIndex) {
        noteColor = Colors.lightGreen;
      } else if (i == currentIndex) {
        noteColor = Colors.yellow;
      } else {
        noteColor = Colors.black;
      }

      if ((offset < 0 || offset > 8) && offset % 2 == 0) {
        canvas.drawLine(
            Offset(x - 20, noteY), Offset(x + 20, noteY), linePaint);
      }

      final paint = Paint()..color = noteColor;
      Rect noteRect =
          Rect.fromCenter(center: Offset(x, noteY), width: 16, height: 10);
      canvas.drawOval(noteRect, paint);

      if (note.contains('#')) {
        final textSpan = TextSpan(
            text: '♯', style: TextStyle(color: noteColor, fontSize: 16));
        final tp =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x - 30, noteY - tp.height / 2));
      }
    }
  }

  void _drawClef(Canvas canvas, Size size) {
    final String clefSymbol =
        clef == ClefType.treble ? "\u{1D11E}" : "\u{1D122}";
    final textSpan = TextSpan(
      text: clefSymbol,
      style: TextStyle(color: Colors.black, fontSize: 60),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    double x = 0;
    double y = 150 - tp.height / 2;
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant SequenceStaffPainter oldDelegate) {
    return oldDelegate.sequence != sequence ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.clef != clef;
  }
}

/// Datenklasse für eine Klaviertaste.
class PianoKeyData {
  final String note;
  final bool isBlack;
  final int whiteIndex; // Position unter den weißen Tasten
  PianoKeyData(
      {required this.note, required this.isBlack, required this.whiteIndex});
}

/// Generiert die 88 Tasten eines Flügels (von A0 bis C8).
List<PianoKeyData> generateFullPianoKeys() {
  List<PianoKeyData> keys = [];
  int whiteKeyCounter = 0;
  // Definition der Note-Reihenfolge für Oktave 0.
  List<String> octave0 = ["A", "A#", "B"];
  for (String note in octave0) {
    bool isBlack = note.contains('#');
    keys.add(PianoKeyData(
        note: "${note}0",
        isBlack: isBlack,
        whiteIndex: isBlack ? whiteKeyCounter - 1 : whiteKeyCounter));
    if (!isBlack) whiteKeyCounter++;
  }
  // Oktaven 1 bis 7.
  for (int octave = 1; octave <= 7; octave++) {
    List<String> notes = [
      "C",
      "C#",
      "D",
      "D#",
      "E",
      "F",
      "F#",
      "G",
      "G#",
      "A",
      "A#",
      "B"
    ];
    for (String note in notes) {
      bool isBlack = note.contains('#');
      keys.add(PianoKeyData(
          note: "$note$octave",
          isBlack: isBlack,
          whiteIndex: isBlack ? whiteKeyCounter - 1 : whiteKeyCounter));
      if (!isBlack) whiteKeyCounter++;
    }
  }
  // Oktave 8: Nur C8.
  keys.add(
      PianoKeyData(note: "C8", isBlack: false, whiteIndex: whiteKeyCounter));
  whiteKeyCounter++;
  return keys;
}

/// Zeichnet einen kompletten Flügel (vollständige Klaviertastatur).
/// Die weißen Tasten werden in einer horizontal scrollbaren Zeile dargestellt;
/// die schwarzen Tasten werden als Positioned-Widgets darüber gelegt.
/// Mit der Option 'showKeyLabels' kannst Du steuern, ob die Notenbeschriftung angezeigt wird.
class FullPianoKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;
  final String? lastTappedNote;
  final bool? lastTapCorrect;
  final bool showKeyLabels;
  const FullPianoKeyboard({
    Key? key,
    required this.onKeyTap,
    this.lastTappedNote,
    this.lastTapCorrect,
    this.showKeyLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<PianoKeyData> keys = generateFullPianoKeys();
    // Filtere die weißen Tasten für die Hintergrund-Reihe.
    List<PianoKeyData> whiteKeys = keys.where((key) => !key.isBlack).toList();
    // Feste Breite pro weißer Taste.
    double whiteKeyWidth = 40;
    double whiteKeyHeight = 150;
    double totalWidth = whiteKeys.length * whiteKeyWidth;
    List<PianoKeyData> blackKeys = keys.where((key) => key.isBlack).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: totalWidth,
        height: whiteKeyHeight,
        child: Stack(
          children: [
            // Weiße Tasten als Row – interaktiv durch GestureDetector.
            Row(
              children: whiteKeys.map((keyData) {
                Color bgColor = Colors.white;
                if (keyData.note == lastTappedNote) {
                  bgColor = (lastTapCorrect ?? false)
                      ? Colors.lightGreen
                      : Colors.orange;
                }
                return GestureDetector(
                  onTap: () => onKeyTap(keyData.note),
                  child: Container(
                    width: whiteKeyWidth,
                    height: whiteKeyHeight,
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: showKeyLabels
                          ? Text(keyData.note, style: TextStyle(fontSize: 10))
                          : Container(),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Schwarze Tasten, positioniert zwischen den weißen Tasten.
            ...blackKeys.map((keyData) {
              double left = (keyData.whiteIndex + 1) * whiteKeyWidth -
                  (whiteKeyWidth * 0.3);
              Color bgColor = Colors.black;
              if (keyData.note == lastTappedNote) {
                bgColor = (lastTapCorrect ?? false)
                    ? Colors.lightGreen
                    : Colors.orange;
              }
              return Positioned(
                top: 0,
                left: left,
                width: whiteKeyWidth * 0.6,
                height: whiteKeyHeight * 0.6,
                child: GestureDetector(
                  onTap: () => onKeyTap(keyData.note),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: Colors.black),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(4)),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: showKeyLabels
                          ? Text(keyData.note,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: bgColor == Colors.black
                                      ? Colors.white
                                      : Colors.black))
                          : Container(),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
