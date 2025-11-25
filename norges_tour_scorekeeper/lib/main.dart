import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:async';

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
      title: 'VolleyLive Dommer',
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
  // --- STATE VARIABLER ---
  String homeTeamName = "Lag A";
  String awayTeamName = "Lag B";
  
  // Spillere
  String p1HomeName = "Hjemme 1", p2HomeName = "Hjemme 2";
  String p1AwayName = "Borte 1", p2AwayName = "Borte 2";
  String? p1HomeId, p2HomeId, p1AwayId, p2AwayId;
  String? p1HomeImg, p2HomeImg, p1AwayImg, p2AwayImg;

  // Spill-logikk
  bool isSetupDone = false;
  String servingTeam = ""; // 'home' eller 'away'
  int serverHomeIdx = 1;   // 1 eller 2
  int serverAwayIdx = 1;   // 1 eller 2
  
  // Timeout tracking
  int homeTimeoutsUsed = 0;
  int awayTimeoutsUsed = 0;
  bool techTimeoutTaken = false;

  // Setup-skjerm midlertidige valg
  String? setupServingTeam; // Hvem starter med ballen?
  int setupHomeFirstServer = 1; // Hvem server først for hjemme?
  int setupAwayFirstServer = 1; // Hvem server først for borte?

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        homeTeamName = data['team_a_name'] ?? 'Lag A';
        awayTeamName = data['team_b_name'] ?? 'Lag B';
        final homeScore = data['home_score'] ?? 0;
        final awayScore = data['away_score'] ?? 0;
        final currentSet = data['current_set'] ?? 1;
        
        // Hent Serve-status
        if (data.containsKey('serving_team')) {
          servingTeam = data['serving_team'];
          serverHomeIdx = data['server_home_idx'] ?? 1;
          serverAwayIdx = data['server_away_idx'] ?? 1;
          isSetupDone = true;
        } else {
          isSetupDone = false;
        }

        // Hent Timeout status
        homeTimeoutsUsed = data['timeouts_home'] ?? 0;
        awayTimeoutsUsed = data['timeouts_away'] ?? 0;
        techTimeoutTaken = data['tech_timeout'] ?? false;

        _updatePlayers(data);

        // REGEL-MOTOR
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkGameRules(homeScore, awayScore, currentSet);
        });

        // VIS OPPSETT HVIS KAMP IKKE ER STARTET
        if (!isSetupDone) {
          return _buildSetupScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text("Sett $currentSet"),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showSideSwitchDialog("Manuelt sidebytte"),
              tooltip: "Bytt side",
            ),
            actions: [
               IconButton(
                 icon: const Icon(Icons.timer),
                 color: Colors.blue,
                 onPressed: homeTimeoutsUsed == 0 ? () => _takeTimeout(true) : null,
               ),
               IconButton(
                 icon: const Icon(Icons.timer),
                 color: Colors.red,
                 onPressed: awayTimeoutsUsed == 0 ? () => _takeTimeout(false) : null,
               ),
            ],
          ),
          body: Column(
            children: [
              // --- SCOREBOARD ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreColumn(homeTeamName, homeScore, Colors.blue, homeTimeoutsUsed),
                    const Text("-", style: TextStyle(fontSize: 40, color: Colors.grey)),
                    _buildScoreColumn(awayTeamName, awayScore, Colors.red, awayTimeoutsUsed),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- SPILLER KNAPPER ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildPlayerButton(p1HomeName, p1HomeId, homeTeamName, true, p1HomeImg, 1),
                            const SizedBox(height: 5),
                            _buildPlayerButton(p2HomeName, p2HomeId, homeTeamName, true, p2HomeImg, 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPlayerButton(p1AwayName, p1AwayId, awayTeamName, false, p1AwayImg, 1),
                            const SizedBox(height: 5),
                            _buildPlayerButton(p2AwayName, p2AwayId, awayTeamName, false, p2AwayImg, 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(8.0),
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

  void _updatePlayers(Map<String, dynamic> data) {
    p1HomeName = data['team_a_p1_name'] ?? "Hjemme 1"; p1HomeId = data['team_a_p1_id']; p1HomeImg = data['team_a_p1_img'];
    p2HomeName = data['team_a_p2_name'] ?? "Hjemme 2"; p2HomeId = data['team_a_p2_id']; p2HomeImg = data['team_a_p2_img'];
    p1AwayName = data['team_b_p1_name'] ?? "Borte 1"; p1AwayId = data['team_b_p1_id']; p1AwayImg = data['team_b_p1_img'];
    p2AwayName = data['team_b_p2_name'] ?? "Borte 2"; p2AwayId = data['team_b_p2_id']; p2AwayImg = data['team_b_p2_img'];
  }

  // --- NYTT OPPSETT-SKJERMBILDE ---
  Widget _buildSetupScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text("Kampoppsett")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("1. Hvem starter med serven?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: setupServingTeam == 'home' ? Colors.blue : Colors.grey[200],
                      foregroundColor: setupServingTeam == 'home' ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => setupServingTeam = 'home'),
                    child: Text(homeTeamName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: setupServingTeam == 'away' ? Colors.red : Colors.grey[200],
                      foregroundColor: setupServingTeam == 'away' ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => setupServingTeam = 'away'),
                    child: Text(awayTeamName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text("2. Hvem server FØRST for hjemmelaget?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            _buildServerSelector(homeTeamName, p1HomeName, p2HomeName, setupHomeFirstServer, (val) => setState(() => setupHomeFirstServer = val)),
            
            const SizedBox(height: 20),
            
            const Text("3. Hvem server FØRST for bortelaget?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            _buildServerSelector(awayTeamName, p1AwayName, p2AwayName, setupAwayFirstServer, (val) => setState(() => setupAwayFirstServer = val)),

            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              onPressed: setupServingTeam != null ? _finishSetup : null,
              child: const Text("START KAMP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerSelector(String teamName, String p1, String p2, int currentVal, Function(int) onSelected) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<int>(
            title: Text(p1, overflow: TextOverflow.ellipsis),
            value: 1,
            groupValue: currentVal,
            onChanged: (val) => onSelected(val!),
            activeColor: Colors.blue[900],
          ),
        ),
        Expanded(
          child: RadioListTile<int>(
            title: Text(p2, overflow: TextOverflow.ellipsis),
            value: 2,
            groupValue: currentVal,
            onChanged: (val) => onSelected(val!),
            activeColor: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  void _finishSetup() {
    // ROTASJONS-LOGIKK:
    // Hvis et lag mottar (ikke starter med ball), så roterer de når de vinner sin første ball (Sideout).
    // Derfor: Hvis brukeren velger at "Spiller 1" skal serve først for mottakende lag,
    // så setter vi intern status til "2". Når de vinner ballen, roterer 2 -> 1.
    
    int finalHomeIdx = setupHomeFirstServer;
    int finalAwayIdx = setupAwayFirstServer;

    if (setupServingTeam == 'away') {
      // Hjemme mottar. Hvis P1 skal serve først, sett index til 2 (så den roterer til 1).
      finalHomeIdx = (setupHomeFirstServer == 1) ? 2 : 1;
    } else {
      // Borte mottar. Hvis P1 skal serve først, sett index til 2.
      finalAwayIdx = (setupAwayFirstServer == 1) ? 2 : 1;
    }

    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'serving_team': setupServingTeam,
      'server_home_idx': finalHomeIdx,
      'server_away_idx': finalAwayIdx,
      'status': 'live',
      'timeouts_home': 0,
      'timeouts_away': 0,
      'tech_timeout': false,
    });
  }

  // --- REGELMOTOR ---
  void _checkGameRules(int home, int away, int set) {
    int sum = home + away;
    int switchInterval = (set == 3) ? 5 : 7;
    
    if (sum > 0 && sum % switchInterval == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("SIDEBYTTE! (Sum: $sum)"), backgroundColor: Colors.orange, duration: const Duration(seconds: 4))
      );
    }

    if (set < 3 && sum == 21 && !techTimeoutTaken) {
       _showTimeoutDialog("TEKNISK TIMEOUT", "21 Poeng spilt. Ta 30 sekunder pause.");
       FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({'tech_timeout': true});
    }

    int targetScore = (set == 3) ? 15 : 21;
    if ((home >= targetScore && home >= away + 2) || (away >= targetScore && away >= home + 2)) {
       _showSetWinDialog(home > away ? homeTeamName : awayTeamName, set);
    }
  }

  void _showTimeoutDialog(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg),
              const SizedBox(height: 20),
              const LinearProgressIndicator(), 
            ],
          ),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Ferdig"))],
        );
      },
    );
  }

  void _showSetWinDialog(String winner, int set) {
    if (!ModalRoute.of(context)!.isCurrent) return; 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("$winner vant sett $set!"),
          content: const Text("Er settet ferdig?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Nei")),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _finishSet(); },
              child: const Text("Start neste sett"),
            ),
          ],
        );
      },
    );
  }

  void _showSideSwitchDialog(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  }

  void _takeTimeout(bool isHome) {
    _showTimeoutDialog("TIMEOUT", "${isHome ? homeTeamName : awayTeamName} tar timeout.");
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      isHome ? 'timeouts_home' : 'timeouts_away': 1,
    });
  }

  void _finishSet() {
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'home_score': 0, 'away_score': 0,
      'current_set': FieldValue.increment(1),
      'timeouts_home': 0, 'timeouts_away': 0,
      'tech_timeout': false,
      'serving_team': null // Tving nytt oppsett for neste sett (valgfritt)
    });
  }

  Widget _buildScoreColumn(String team, int score, Color color, int timeouts) {
    return Column(
      children: [
        Text(team, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text("$score", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
        if (timeouts > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.yellow[700], borderRadius: BorderRadius.circular(4)),
            child: const Text("T", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
      ],
    );
  }

  Widget _buildPlayerButton(String name, String? id, String team, bool isHomeTeam, String? imageUrl, int playerIdx) {
    // Sjekk hvem som server
    bool isServing = false;
    if (isHomeTeam && servingTeam == 'home' && serverHomeIdx == playerIdx) isServing = true;
    if (!isHomeTeam && servingTeam == 'away' && serverAwayIdx == playerIdx) isServing = true;

    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isHomeTeam ? Colors.blue[50] : Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isServing ? const BorderSide(color: Colors.orange, width: 3) : BorderSide.none),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onPressed: () => _showActionSheet(name, id, team, isHomeTeam, playerIdx),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     if (imageUrl != null && imageUrl.isNotEmpty)
                      CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl))
                    else
                      const CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isServing)
                const Positioned(
                  right: 0, top: 0,
                  child: Icon(Icons.sports_volleyball, color: Colors.orange, size: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showActionSheet(String name, String? id, String team, bool isHomeTeam, int playerIdx) {
    
    // 1. Sjekk om denne spilleren faktisk server nå
    bool isServer = false;
    if (isHomeTeam && servingTeam == 'home' && serverHomeIdx == playerIdx) isServer = true;
    if (!isHomeTeam && servingTeam == 'away' && serverAwayIdx == playerIdx) isServer = true;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            children: [
              Text("Hva gjorde $name?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    // GRØNN KOLONNE (Positivt)
                    Expanded(
                      child: Column(
                        children: [
                          _actionBtn("ANGREP (Kill)", Colors.green, () => _registerStat(name, id, team, isHomeTeam, "Kill", true)),
                          const SizedBox(height: 10),
                          _actionBtn("BLOKK POENG", Colors.green, () => _registerStat(name, id, team, isHomeTeam, "Block", true)),
                          
                          // VISES KUN HVIS SERVER:
                          if (isServer) ...[
                            const SizedBox(height: 10),
                            _actionBtn("SERVE ESS", Colors.green, () => _handleAceSelection(name, id, team, isHomeTeam)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // RØD KOLONNE (Feil)
                    Expanded(
                      child: Column(
                        children: [
                          _actionBtn("ANGREPSFEIL", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Attack Error", false)),
                          
                          // VISES KUN HVIS SERVER:
                          if (isServer) ...[
                            const SizedBox(height: 10),
                            _actionBtn("SERVEFEIL", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Service Error", false)),
                          ],
                          
                          const SizedBox(height: 10),
                          _actionBtn("TEKNISK / NETT", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Technical Error", false)),
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
          onPressed: () { Navigator.pop(context); onTap(); },
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _updateServeLogic(bool pointToHome) {
    bool homeWasServing = servingTeam == 'home';
    String nextServingTeam = pointToHome ? 'home' : 'away';
    
    int nextServerHomeIdx = serverHomeIdx;
    int nextServerAwayIdx = serverAwayIdx;

    if (homeWasServing && !pointToHome) {
      // Borte vant serven (Sideout) -> Roter Borte sin server
      nextServerAwayIdx = (serverAwayIdx == 1) ? 2 : 1;
    } else if (!homeWasServing && pointToHome) {
      // Hjemme vant serven (Sideout) -> Roter Hjemme sin server
      nextServerHomeIdx = (serverHomeIdx == 1) ? 2 : 1;
    }

    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'serving_team': nextServingTeam,
      'server_home_idx': nextServerHomeIdx,
      'server_away_idx': nextServerAwayIdx,
    });
  }

 void _registerStat(String name, String? id, String team, bool isHomeTeam, String actionType, bool isPositive) {
    bool pointToHome = isPositive ? isHomeTeam : !isHomeTeam;

    // --- NY LOGIKK: Beregn Fase (Sideout vs Break Point) ---
    // Vi må gjøre dette FØR vi oppdaterer serven, mens vi fortsatt vet hvem som servet denne ballen.
    String phase = "Unknown";
    bool homeWasServing = servingTeam == 'home';

    if (pointToHome) {
      // Hjemmelaget vant poenget.
      // Hvis de servet selv -> Break Point. Hvis bortelaget servet -> Sideout.
      phase = homeWasServing ? "Break Point" : "Sideout";
    } else {
      // Bortelaget vant poenget.
      // Hvis de servet selv -> Break Point. Hvis hjemmelaget servet -> Sideout.
      phase = !homeWasServing ? "Break Point" : "Sideout";
    }

    // 1. Oppdater Serve og Rotasjon (dette endrer servingTeam til neste ball)
    _updateServeLogic(pointToHome);

    // 2. Oppdater Score
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });

    // 3. Logg Event (NÅ MED FASE!)
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': name,
      'player_id': id,
      'team': team,
      'action': actionType,
      'point_to': pointToHome ? 'home' : 'away',
      'phase': phase, // <--- HER ER GULLET! 
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // 4. Automatisk Assist logikk
    if (actionType == "Kill" || actionType == "Attack Error") {
       
       String partnerName = "";
       String? partnerId;

       if (isHomeTeam) {
         if (name == p1HomeName) { partnerName = p2HomeName; partnerId = p2HomeId; }
         else { partnerName = p1HomeName; partnerId = p1HomeId; }
       } else {
         if (name == p1AwayName) { partnerName = p2AwayName; partnerId = p2AwayId; }
         else { partnerName = p1AwayName; partnerId = p1AwayId; }
       }

       if (actionType == "Kill") {
         FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
            'player_name': partnerName, 'player_id': partnerId, 'team': team,
            'action': "Set Assist", 'point_to': "none", 'phase': phase, // Assist får også fase!
            'timestamp': FieldValue.serverTimestamp(),
         });
       }

       FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
          'player_name': partnerName, 'player_id': partnerId, 'team': team,
          'action': "Set Attempt", 'point_to': "none", 'phase': phase,
          'timestamp': FieldValue.serverTimestamp(),
       });
    }
  }

  void _handleAceSelection(String sName, String? sId, String sTeam, bool isHome) {
     // 1. Finn motstanderlagets spillere
     String r1Name = isHome ? p1AwayName : p1HomeName;
     String r2Name = isHome ? p2AwayName : p2HomeName;
     String? r1Id  = isHome ? p1AwayId : p1HomeId;
     String? r2Id  = isHome ? p2AwayId : p2HomeId;
     String rTeam  = isHome ? awayTeamName : homeTeamName;

     // 2. Vis dialogboks
     showDialog(
       context: context,
       builder: (context) {
         return AlertDialog(
           title: const Text("Hvem bommet på mottak?"),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               ElevatedButton(
                 onPressed: () {
                   Navigator.pop(context);
                   // Registrer Ess på server, og Feil på mottaker 1
                   _registerAceComplex(sName, sId, sTeam, isHome, r1Name, r1Id, rTeam);
                 },
                 child: Text(r1Name, style: const TextStyle(fontSize: 18)),
               ),
               const SizedBox(height: 10),
               ElevatedButton(
                 onPressed: () {
                   Navigator.pop(context);
                   // Registrer Ess på server, og Feil på mottaker 2
                   _registerAceComplex(sName, sId, sTeam, isHome, r2Name, r2Id, rTeam);
                 },
                 child: Text(r2Name, style: const TextStyle(fontSize: 18)),
               ),
             ],
           ),
         );
       },
     );
  }

  void _registerAceComplex(String sName, String? sId, String sTeam, bool isHome, String vName, String? vId, String vTeam) {
    // A. Registrer poenget (Ace)
    _registerStat(sName, sId, sTeam, isHome, "Ace", true);

    // B. Registrer mottaksfeilen (uten å gi poeng, det gjorde vi over)
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': vName,
      'player_id': vId,
      'team': vTeam,
      'action': "Reception Error", 
      'point_to': "none",          
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _undoLastAction() async {
     final events = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').orderBy('timestamp', descending: true).limit(1).get();
     if (events.docs.isNotEmpty) {
        final data = events.docs.first.data();
        bool pointHome = data['point_to'] == 'home';
        FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
          pointHome ? 'home_score' : 'away_score': FieldValue.increment(-1),
        });
        events.docs.first.reference.delete();
     }
  }
}