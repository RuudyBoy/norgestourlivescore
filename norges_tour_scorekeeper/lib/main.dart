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
      title: 'Norges Tour Scorekeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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
    // MAGIEN SKJER HER: Vi leser nettadressen!
    // Vi ser etter "?matchId=..." i URL-en
    final uri = Uri.base; 
    matchId = uri.queryParameters['matchId'];
  }

  @override
  Widget build(BuildContext context) {
    // Scenario 1: Ingen ID i linken (Vanlig besøk)
    if (matchId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                "Ingen kamp valgt.",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text("Vennligst scan QR-koden fra sekretariatet."),
            ],
          ),
        ),
      );
    }

    // Scenario 2: Vi fant en ID! Vis Scoreboardet.
    return ScoreboardPage(matchId: matchId!);
  }
}

// --- SELVE KAMPSTYRINGEN (Kopiert og tilpasset fra Admin) ---
class ScoreboardPage extends StatelessWidget {
  final String matchId;

  const ScoreboardPage({super.key, required this.matchId});

  void _updateScore(String field, int delta) {
    FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      field: FieldValue.increment(delta),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dommerpanel"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Fant ikke kampen. Feil ID?"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          final teamA = data['team_a_name'] ?? 'Lag A';
          final teamB = data['team_b_name'] ?? 'Lag B';
          final homeScore = data['home_score'] ?? 0;
          final awayScore = data['away_score'] ?? 0;
          final status = data['status'] ?? 'scheduled';

          return Column(
            children: [
              // Status Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: status == 'live' ? Colors.red : Colors.grey[300],
                width: double.infinity,
                child: Text(
                  status == 'live' ? "KAMPEN ER LIVE" : "STATUS: ${status.toUpperCase()}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status == 'live' ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    // --- HJEMMELAG ---
                    Expanded(
                      child: _buildTeamColumn(teamA, homeScore, 'home_score', Colors.blue[50]!),
                    ),
                    // Skillelinje
                    Container(width: 2, color: Colors.grey[300]),
                    // --- BORTELAG ---
                    Expanded(
                      child: _buildTeamColumn(teamB, awayScore, 'away_score', Colors.red[50]!),
                    ),
                  ],
                ),
              ),
              
              // Start / Stopp knapper
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (status != 'live')
                      ElevatedButton.icon(
                        onPressed: () => FirebaseFirestore.instance.collection('matches').doc(matchId).update({'status': 'live'}),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("START MATCH"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(20)),
                      ),
                    if (status == 'live')
                      ElevatedButton.icon(
                        onPressed: () => FirebaseFirestore.instance.collection('matches').doc(matchId).update({'status': 'finished'}),
                        icon: const Icon(Icons.stop),
                        label: const Text("AVSLUTT"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(20)),
                      ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamColumn(String name, int score, String field, Color bg) {
    return Container(
      color: bg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 30),
          Text("$score", style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          // Knapper
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(Icons.remove, () => _updateScore(field, -1)),
              const SizedBox(width: 20),
              _circleButton(Icons.add, () => _updateScore(field, 1), isBig: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {bool isBig = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.all(isBig ? 25 : 15),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      child: Icon(icon, size: isBig ? 40 : 24),
    );
  }
}