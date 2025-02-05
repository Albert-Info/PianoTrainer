import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

/// Unterscheidung der Modi: Einzelnoten vs. Sequenz (10 Noten)
enum PracticeMode { individual, sequence }

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

  // Liste aller verfügbaren Noten im Bereich: C4 bis B5 plus oberstes C (C6)
  final List<String> _allNotes = [];
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
    // Erzeuge alle Noten für die Oktaven 4 und 5:
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
        _allNotes.add('$note$octave');
      }
    }
    _allNotes.add('C6'); // oberstes C

    _resetPractice();
  }

  /// Setzt den Zustand zurück (beim Modi-Wechsel oder per Button)
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

  /// Einzelnoten-Modus: Wähle eine zufällige Note.
  void _pickRandomNote() {
    setState(() {
      _currentNote = _allNotes[Random().nextInt(_allNotes.length)];
    });
  }

  /// Sequenz-Modus: Erzeuge eine Liste mit 10 zufälligen Noten.
  void _generateSequence() {
    final random = Random();
    _sequence =
        List.generate(10, (_) => _allNotes[random.nextInt(_allNotes.length)]);
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
      // Richtig: Zeige 500 ms lang hellgrünes Highlight, danach weiter.
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
      // Falsch: Zeige 500 ms lang orangenes Highlight, danach erneute Eingabe ermöglichen.
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
            SizedBox(height: 20),
            // Umschaltbuttons für die Modi.
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
            SizedBox(height: 20),
            Text(
              _mode == PracticeMode.individual
                  ? 'Erkenne die Note:'
                  : 'Spiele die Sequenz – Note für Note:',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            // Im Einzelnoten-Modus: Zeige die aktuelle Note auf dem Notensystem.
            // Im Sequenz-Modus: Zeichne alle 10 Noten gleichzeitig auf dem Notensheet.
            SizedBox(
              height: 220,
              child: CustomPaint(
                size: Size(double.infinity, 220),
                painter: _mode == PracticeMode.individual
                    ? StaffPainter(_currentExpectedNote)
                    : SequenceStaffPainter(_sequence, _currentIndex),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Spiele die Note auf der Klaviertastatur:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            // Klaviertastatur: Hier wird _keine_ Lösungsvorschau angezeigt.
            Container(
              height: 150,
              child: PianoKeyboard(
                onKeyTap: _onKeyTap,
                expectedNote: '', // wird nicht genutzt
                lastTappedNote: _lastTappedNote,
                lastTapCorrect: _lastTapCorrect,
              ),
            ),
            SizedBox(height: 20),
            // Button zum Generieren einer neuen Sequenz bzw. einer neuen Note.
            if (_mode == PracticeMode.sequence)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _generateSequence();
                    _currentIndex = 0;
                  });
                },
                child: Text("Neue Sequenz generieren"),
              )
            else
              ElevatedButton(
                onPressed: _pickRandomNote,
                child: Text("Neue Note"),
              ),
          ],
        ),
      ),
    );
  }
}

/// Berechnet einen diatonischen Wert zur Positionierung im Notensystem.
/// Hierbei wird nur der Buchstabe (A–G) und die Oktave berücksichtigt.
/// Dabei gilt: C=0, D=1, …, B=6.
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

/// Zeichnet ein Notensystem (Treble‑Schlüssel) und einen einzelnen Notehead.
/// Die Note wird anhand ihres diatonischen Werts positioniert (E4 entspricht hier 30).
class StaffPainter extends CustomPainter {
  final String note;
  StaffPainter(this.note);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    const double step = 10.0;
    const double baseY = 150.0;

    // Zeichne die fünf Linien des Notensystems.
    for (int i = 0; i <= 8; i += 2) {
      double y = baseY - i * step;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), linePaint);
    }

    if (note.isNotEmpty) {
      int offset = getDiatonicValue(note) - 30;
      double noteY = baseY - offset * step;
      double noteX = size.width / 2;

      // Ledger Lines zeichnen, falls nötig.
      if ((offset < 0 || offset > 8) && offset % 2 == 0) {
        canvas.drawLine(
          Offset(noteX - 20, noteY),
          Offset(noteX + 20, noteY),
          linePaint,
        );
      }

      // Zeichne den Notehead.
      final notePaint = Paint()..color = Colors.black;
      Rect noteRect =
          Rect.fromCenter(center: Offset(noteX, noteY), width: 16, height: 10);
      canvas.drawOval(noteRect, notePaint);

      // Falls es sich um eine #-Note handelt, zeichne ein ♯-Symbol links vom Notehead.
      if (note.contains('#')) {
        final textSpan = TextSpan(
          text: '♯',
          style: TextStyle(color: Colors.black, fontSize: 16),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(noteX - 30, noteY - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaffPainter oldDelegate) {
    return oldDelegate.note != note;
  }
}

/// Zeichnet ein Notensystem, in dem eine ganze Sequenz von Noten (z. B. 10 Noten) horizontal verteilt wird.
/// Dabei wird für jede Note anhand ihres diatonischen Werts die vertikale Position berechnet.
/// Die Note, die aktuell zu spielen ist (currentIndex), wird hervorgehoben.
class SequenceStaffPainter extends CustomPainter {
  final List<String> sequence;
  final int currentIndex;
  SequenceStaffPainter(this.sequence, this.currentIndex);

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
    // Wenn mehr als 1 Note: berechne den horizontalen Abstand.
    double spacing = noteCount > 1 ? availableWidth / (noteCount - 1) : 0;

    // Zeichne das Notensystem (die fünf Linien).
    for (int i = 0; i <= 8; i += 2) {
      double y = baseY - i * step;
      canvas.drawLine(Offset(leftMargin, y),
          Offset(size.width - rightMargin, y), linePaint);
    }

    // Zeichne jede Note in der Sequenz.
    for (int i = 0; i < noteCount; i++) {
      String note = sequence[i];
      // Berechne den x-Wert: gleichmäßig verteilt zwischen leftMargin und (size.width - rightMargin).
      double x = leftMargin + i * spacing;
      int offset = getDiatonicValue(note) - 30;
      double noteY = baseY - offset * step;

      // Bestimme die Farbe des Noteheads:
      // - Bereits korrekt gespielt (i < currentIndex): hellgrün
      // - Aktuell zu spielende Note (i == currentIndex): gelb
      // - Rest: schwarz
      Color noteColor;
      if (i < currentIndex) {
        noteColor = Colors.lightGreen;
      } else if (i == currentIndex) {
        noteColor = Colors.yellow;
      } else {
        noteColor = Colors.black;
      }

      // Falls die Note außerhalb des Systems liegt und exakt auf einer Linienposition ist, zeichne Ledger Lines.
      if ((offset < 0 || offset > 8) && offset % 2 == 0) {
        canvas.drawLine(
          Offset(x - 20, noteY),
          Offset(x + 20, noteY),
          linePaint,
        );
      }

      // Zeichne den Notehead als Oval in der bestimmten Farbe.
      final paint = Paint()..color = noteColor;
      Rect noteRect =
          Rect.fromCenter(center: Offset(x, noteY), width: 16, height: 10);
      canvas.drawOval(noteRect, paint);

      // Falls es sich um eine #-Note handelt, zeichne ein ♯-Symbol links vom Notehead.
      if (note.contains('#')) {
        final textSpan = TextSpan(
          text: '♯',
          style: TextStyle(color: noteColor, fontSize: 16),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - 30, noteY - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SequenceStaffPainter oldDelegate) {
    return oldDelegate.sequence != sequence ||
        oldDelegate.currentIndex != currentIndex;
  }
}

/// Zeichnet eine Klaviertastatur für den Bereich von C4 bis C6.
/// Die weißen Tasten werden in einer Row dargestellt und
/// die schwarzen Tasten – entsprechend ihrer Position wie auf einem echten Klavier – werden überlagert.
/// Beim Tastendruck wird (temporär) das Ergebnis hervorgehoben.
class PianoKeyboard extends StatelessWidget {
  final Function(String) onKeyTap;
  // Der Parameter expectedNote wird hier _nicht_ verwendet, um die Lösung zu verbergen.
  final String expectedNote;
  final String? lastTappedNote;
  final bool? lastTapCorrect;
  const PianoKeyboard({
    Key? key,
    required this.onKeyTap,
    required this.expectedNote,
    this.lastTappedNote,
    this.lastTapCorrect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
        // Es gibt 15 weiße Tasten: C4, D4, E4, F4, G4, A4, B4, C5, D5, E5, F5, G5, A5, B5, C6.
        int numWhiteKeys = 15;
        double whiteKeyWidth = totalWidth / numWhiteKeys;
        double whiteKeyHeight = 150;
        double blackKeyWidth = whiteKeyWidth * 0.6;
        double blackKeyHeight = whiteKeyHeight * 0.6;

        // Definition der weißen Tasten.
        final List<String> whiteNotes = [
          'C4',
          'D4',
          'E4',
          'F4',
          'G4',
          'A4',
          'B4',
          'C5',
          'D5',
          'E5',
          'F5',
          'G5',
          'A5',
          'B5',
          'C6',
        ];

        // Für die schwarzen Tasten wird hier der Index der weißen Taste angegeben,
        // vor der die schwarze Taste platziert werden soll.
        final List<Map<String, dynamic>> blackKeys = [
          {'note': 'C#4', 'whiteIndex': 0},
          {'note': 'D#4', 'whiteIndex': 1},
          // Zwischen E4 und F4 gibt es keine schwarze Taste.
          {'note': 'F#4', 'whiteIndex': 3},
          {'note': 'G#4', 'whiteIndex': 4},
          {'note': 'A#4', 'whiteIndex': 5},
          // Für Oktave 5:
          {'note': 'C#5', 'whiteIndex': 7},
          {'note': 'D#5', 'whiteIndex': 8},
          // Zwischen E5 und F5 gibt es keine schwarze Taste.
          {'note': 'F#5', 'whiteIndex': 10},
          {'note': 'G#5', 'whiteIndex': 11},
          {'note': 'A#5', 'whiteIndex': 12},
        ];

        return Stack(
          children: [
            // Zeichne die weißen Tasten in einer Row.
            Row(
              children: whiteNotes.map((note) {
                Color bgColor = Colors.white;
                if (note == lastTappedNote) {
                  bgColor = (lastTapCorrect ?? false)
                      ? Colors.lightGreen
                      : Colors.orange;
                }
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onKeyTap(note),
                    child: Container(
                      height: whiteKeyHeight,
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: Colors.black),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          note,
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Zeichne die schwarzen Tasten, positioniert zwischen den entsprechenden weißen Tasten.
            ...blackKeys.map((keyInfo) {
              int whiteIndex = keyInfo['whiteIndex'];
              // Der Mittelpunkt der schwarzen Taste liegt genau an der Grenze zwischen der weißen Taste
              // mit Index whiteIndex und der nächsten.
              double centerX = (whiteIndex + 1) * whiteKeyWidth;
              double left = centerX - blackKeyWidth / 2;
              String note = keyInfo['note'];
              Color bgColor = Colors.black;
              if (note == lastTappedNote) {
                bgColor = (lastTapCorrect ?? false)
                    ? Colors.lightGreen
                    : Colors.orange;
              }
              return Positioned(
                top: 0,
                left: left,
                width: blackKeyWidth,
                height: blackKeyHeight,
                child: GestureDetector(
                  onTap: () => onKeyTap(note),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: Colors.black),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(4)),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 10,
                          color: (bgColor == Colors.black)
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
