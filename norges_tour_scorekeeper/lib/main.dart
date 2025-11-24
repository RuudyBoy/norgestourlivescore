import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ScorekeeperApp());
}

class ScorekeeperApp extends StatelessWidget {
  const ScorekeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolleyLive Scorekeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? matchId;

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    matchId = uri.queryParameters['matchId'];
  }

  @override
  Widget build(BuildContext context) {
    if (matchId == null) {
      return const Scaffold(
        body: Center(child: Text("Ingen kamp valgt. Scan QR-kode.")),
      );
    }
    return ScoreboardPage(matchId: matchId!);
  }
}

class ScoreboardPage extends StatefulWidget {
  final String matchId;
  const ScoreboardPage({super.key, required this.matchId});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  // Midlertidige navn (kan endres av dommer)
  String p1Home = "Hjemme 1";
  String p2Home = "Hjemme 2";
  String p1Away = "Borte 1";
  String p2Away = "Borte 2";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final homeTeam = data['team_a_name'] ?? 'Lag A';
        final awayTeam = data['team_b_name'] ?? 'Lag B';
        final homeScore = data['home_score'] ?? 0;
        final awayScore = data['away_score'] ?? 0;
        final currentSet = data['current_set'] ?? 1; // Vi kan legge til sett-logikk senere
        
        return Scaffold(
          appBar: AppBar(
            title: const Text("VolleyLive Dommer"),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editPlayerNamesDialog(),
                tooltip: "Endre spillernavn",
              )
            ],
          ),
          body: Column(
            children: [
              // --- SCOREBOARD TOPP ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreColumn(homeTeam, homeScore, Colors.blue),
                    const Text("-", style: TextStyle(fontSize: 40, color: Colors.grey)),
                    _buildScoreColumn(awayTeam, awayScore, Colors.red),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- SPILLER KNAPPER (Hovedområdet) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // HJEMMELAG SPILLERE
                      Expanded(
                        child: Column(
                          children: [
                            _buildPlayerButton(p1Home, homeTeam, true),
                            const SizedBox(height: 10),
                            _buildPlayerButton(p2Home, homeTeam, true),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // BORTELAG SPILLERE
                      Expanded(
                        child: Column(
                          children: [
                            _buildPlayerButton(p1Away, awayTeam, false),
                            const SizedBox(height: 10),
                            _buildPlayerButton(p2Away, awayTeam, false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // UNDO KNAPP (Viktig når man trykker feil!)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _undoLastAction,
                  icon: const Icon(Icons.undo),
                  label: const Text("Angre siste poeng"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI Widgets ---

  Widget _buildScoreColumn(String team, int score, Color color) {
    return Column(
      children: [
        Text(team, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text("$score", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlayerButton(String player, String team, bool isHomeTeam) {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isHomeTeam ? Colors.blue[50] : Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: () => _showActionSheet(player, team, isHomeTeam),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 30, color: Colors.grey),
              const SizedBox(height: 5),
              Text(player, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(team, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // --- MENYEN SOM KOMMER OPP (Action Sheet) ---
  void _showActionSheet(String player, String team, bool isHomeTeam) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hva gjorde $player?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    // KOLONNE 1: POENG TIL OSS (Grønn)
                    Expanded(
                      child: Column(
                        children: [
                          _actionBtn("ANGREP (Kill)", Colors.green, () => _registerStat(player, team, isHomeTeam, "Kill", true)),
                          const SizedBox(height: 10),
                          _actionBtn("BLOKK POENG", Colors.green, () => _registerStat(player, team, isHomeTeam, "Block", true)),
                          const SizedBox(height: 10),
                          _actionBtn("SERVE ESS", Colors.green, () => _registerStat(player, team, isHomeTeam, "Ace", true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // KOLONNE 2: FEIL (Rød - gir poeng til motstander)
                    Expanded(
                      child: Column(
                        children: [
                          _actionBtn("ANGREPSFEIL (Ut/Nett)", Colors.red[300]!, () => _registerStat(player, team, isHomeTeam, "Attack Error", false)),
                          const SizedBox(height: 10),
                          _actionBtn("SERVEFEIL", Colors.red[300]!, () => _registerStat(player, team, isHomeTeam, "Service Error", false)),
                          const SizedBox(height: 10),
                          _actionBtn("TEKNISK / NETT", Colors.red[300]!, () => _registerStat(player, team, isHomeTeam, "Technical Error", false)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Lukk menyen
            onTap(); // Kjør logikk
          },
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // --- LOGIKK FOR Å OPPDATERE FIREBASE ---
  void _registerStat(String player, String team, bool isHomeTeam, String actionType, bool isPositive) {
    // isPositive = true betyr at spilleren gjorde noe bra (Kill/Ace) -> Poeng til SPILLERENS lag.
    // isPositive = false betyr at spilleren gjorde noe dumt (Feil) -> Poeng til MOTSATT lag.
    
    bool pointToHome;
    if (isPositive) {
      pointToHome = isHomeTeam; // Hjemmespiller gjorde noe bra -> Hjemmepoeng
    } else {
      pointToHome = !isHomeTeam; // Hjemmespiller gjorde feil -> Bortepoeng
    }

    // 1. Oppdater Score
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });

    // 2. Logg hendelsen for statistikk (Dette legger vi i en under-kolleksjon 'events')
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player': player,
      'team': team,
      'action': actionType,
      'point_to': pointToHome ? 'home' : 'away',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _undoLastAction() async {
    // Finn siste hendelse
    final events = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (events.docs.isNotEmpty) {
      final lastEvent = events.docs.first;
      final data = lastEvent.data();
      
      // Trekk fra poenget
      bool pointToHome = data['point_to'] == 'home';
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        pointToHome ? 'home_score' : 'away_score': FieldValue.increment(-1),
      });

      // Slett hendelsen fra loggen
      lastEvent.reference.delete();
    }
  }

  void _editPlayerNamesDialog() {
    // Enkel dialog for å sette navnene (kun lokalt i appen foreløpig)
    TextEditingController c1 = TextEditingController(text: p1Home);
    TextEditingController c2 = TextEditingController(text: p2Home);
    TextEditingController c3 = TextEditingController(text: p1Away);
    TextEditingController c4 = TextEditingController(text: p2Away);

    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("Sett spillernavn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Hjemmelag"),
            TextField(controller: c1, decoration: const InputDecoration(hintText: "Spiller 1")),
            TextField(controller: c2, decoration: const InputDecoration(hintText: "Spiller 2")),
            const SizedBox(height: 20),
            const Text("Bortelag"),
            TextField(controller: c3, decoration: const InputDecoration(hintText: "Spiller 1")),
            TextField(controller: c4, decoration: const InputDecoration(hintText: "Spiller 2")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Avbryt")),
          ElevatedButton(onPressed: () {
            setState(() {
              p1Home = c1.text; p2Home = c2.text;
              p1Away = c3.text; p2Away = c4.text;
            });
            Navigator.pop(context);
          }, child: const Text("Lagre"))
        ],
      );
    });
  }
}
