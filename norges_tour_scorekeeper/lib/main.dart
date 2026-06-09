import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

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
      theme: AppTheme.dark.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.nightSurface0, // Fallback
            image: DecorationImage(
              image: const AssetImage('assets/images/hero_bg.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(AppColors.nightSurface0.withOpacity(0.85), BlendMode.srcOver),
            ),
          ),
          child: child,
        );
      },
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
        backgroundColor: Colors.transparent,
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
  // --- STATE ---
  String homeTeamName = "Lag A", awayTeamName = "Lag B";
  String p1HomeName = "Hjemme 1", p2HomeName = "Hjemme 2";
  String p1AwayName = "Borte 1", p2AwayName = "Borte 2";
  String? p1HomeId, p2HomeId, p1AwayId, p2AwayId;
  String? p1HomeImg, p2HomeImg, p1AwayImg, p2AwayImg;

  bool isSetupDone = false;
  String servingTeam = ""; 
  int serverHomeIdx = 1, serverAwayIdx = 1;
  int homeTimeoutsUsed = 0, awayTimeoutsUsed = 0;
  bool techTimeoutTaken = false;

  int _lastCheckedHome = -1;
  int _lastCheckedAway = -1;
  int _lastCheckedSet = -1;

  String? setupServingTeam;
  int setupHomeFirstServer = 1, setupAwayFirstServer = 1;
  String setupHomeColor = 'blue', setupAwayColor = 'red';
  bool setupStartSwapped = false;

  bool isSwapped = false;
  int lastSwappedScore = -1;
  String homeColorStr = 'blue', awayColorStr = 'red';

  Color _getColor(String colorStr) {
    switch (colorStr) {
      case 'red': return AppColors.coral;
      case 'blue': return AppColors.blueBright;
      case 'green': return AppColors.green;
      case 'orange': return Colors.orangeAccent;
      case 'purple': return Colors.deepPurpleAccent;
      case 'black': return AppColors.nightSurface0;
      case 'yellow': return Colors.amber;
      default: return AppColors.nightInk3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('matches').doc(widget.matchId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final data = snapshot.data!.data() as Map<String, dynamic>;
        _initializeData(data);

        if (!isSetupDone) return _buildSetupScreen();

        final homeScore = data['home_score'] ?? 0;
        final awayScore = data['away_score'] ?? 0;
        final currentSet = data['current_set'] ?? 1;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (homeScore != _lastCheckedHome || awayScore != _lastCheckedAway || currentSet != _lastCheckedSet) {
            _lastCheckedHome = homeScore;
            _lastCheckedAway = awayScore;
            _lastCheckedSet = currentSet;
            _checkGameRules(homeScore, awayScore, currentSet);
          }
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/spikedunk_logo.png', height: 40, fit: BoxFit.contain),
                const SizedBox(width: 8),
                Text("Sett $currentSet"),
              ],
            ),
            centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({'is_swapped': !isSwapped})),
            actions: [
              IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoModal),
              IconButton(icon: const Icon(Icons.timer), color: _getColor(homeColorStr), onPressed: homeTimeoutsUsed == 0 ? () => _takeTimeout(true) : null),
              IconButton(icon: const Icon(Icons.timer), color: _getColor(awayColorStr), onPressed: awayTimeoutsUsed == 0 ? () => _takeTimeout(false) : null),
            ],
          ),
          body: Column(
            children: [
              _buildScoreboard(homeScore, awayScore),
              const Divider(height: 1),
              _buildPlayerArea(),
              _buildUndoButton(),
            ],
          ),
        );
      },
    );
  }

  // --- HJELPEFUNKSJONER FOR UI ---

  Widget _buildScoreboard(int homeScore, int awayScore) {
    Widget homeCol = _buildScoreColumn(homeTeamName, homeScore, _getColor(homeColorStr), homeTimeoutsUsed, true);
    Widget awayCol = _buildScoreColumn(awayTeamName, awayScore, _getColor(awayColorStr), awayTimeoutsUsed, false);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: isSwapped ? [awayCol, Text("-", style: AppText.dispScore(60).copyWith(color: AppColors.nightInk3)), homeCol] : [homeCol, Text("-", style: AppText.dispScore(60).copyWith(color: AppColors.nightInk3)), awayCol],
      ),
    );
  }

  Widget _buildPlayerArea() {
    Widget homePlayers = Expanded(child: Column(children: [
      _buildPlayerButton(p1HomeName, p1HomeId, homeTeamName, true, p1HomeImg, 1),
      const SizedBox(height: 5),
      _buildPlayerButton(p2HomeName, p2HomeId, homeTeamName, true, p2HomeImg, 2),
    ]));
    Widget awayPlayers = Expanded(child: Column(children: [
      _buildPlayerButton(p1AwayName, p1AwayId, awayTeamName, false, p1AwayImg, 1),
      const SizedBox(height: 5),
      _buildPlayerButton(p2AwayName, p2AwayId, awayTeamName, false, p2AwayImg, 2),
    ]));

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: isSwapped ? [awayPlayers, const SizedBox(width: 5), homePlayers] : [homePlayers, const SizedBox(width: 5), awayPlayers],
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: _undoLastAction,
        icon: const Icon(Icons.undo),
        label: Text("Angre siste poeng", style: AppText.uiCta),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.nightSurface2, foregroundColor: Colors.white),
      ),
    );
  }

  // --- STATS OG LOGIKK ---

  void _showActionSheet(String name, String? id, String team, bool isHomeTeam, int playerIdx) {
    bool isServer = (isHomeTeam && servingTeam == 'home' && serverHomeIdx == playerIdx) ||
                    (!isHomeTeam && servingTeam == 'away' && serverAwayIdx == playerIdx);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 380,
        child: Column(
          children: [
            Text("Hva gjorde $name?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: Row(
              children: [
                Expanded(child: Column(children: [
                  _actionBtn("ANGREP (Kill)", Colors.green, () => _handleKillSelection(name, id, team, isHomeTeam)),
                  const SizedBox(height: 10),
                  _actionBtn("BLOKK POENG", Colors.green, () => _handleBlockSelection(name, id, team, isHomeTeam)),
                  if (isServer) ...[
                    const SizedBox(height: 10),
                    _actionBtn("SERVE ESS", Colors.green, () => _handleAceSelection(name, id, team, isHomeTeam, "Ace")),
                  ],
                ])),
                const SizedBox(width: 20),
                Expanded(child: Column(children: [
                  _actionBtn("ANGREPSFEIL", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Attack Error", false)),
                  if (isServer) ...[
                    const SizedBox(height: 10),
                    _actionBtn("SERVEFEIL", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Service Error", false)),
                  ],
                  const SizedBox(height: 10),
                  _actionBtn("TEKNISK / NETT", Colors.red[300]!, () => _registerStat(name, id, team, isHomeTeam, "Technical Error", false)),
                ])),
              ],
            )),
          ],
        ),
      ),
    );
  }

  void _registerStat(String name, String? id, String team, bool isHomeTeam, String actionType, bool isPositive, {String? subType}) {
    bool pointToHome = isPositive ? isHomeTeam : !isHomeTeam;
    String phase = servingTeam == (pointToHome ? (isHomeTeam ? 'home' : 'away') : (isHomeTeam ? 'away' : 'home')) ? "Break Point" : "Sideout";
    
    // Spesialhåndtering av fase før rotasjon:
    bool wasHomeServing = servingTeam == 'home';
    phase = pointToHome ? (wasHomeServing ? "Break Point" : "Sideout") : (!wasHomeServing ? "Break Point" : "Sideout");

    _updateServeLogic(pointToHome);

    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });

    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': name,
      'player_id': id,
      'team': team,
      'action': actionType,
      'sub_type': subType,
      'point_to': pointToHome ? 'home' : 'away',
      'phase': phase,
      'timestamp': FieldValue.serverTimestamp(),
      'prev_serving_team': servingTeam,
      'prev_server_home_idx': serverHomeIdx,
      'prev_server_away_idx': serverAwayIdx,
    });

    if (actionType == "Kill" || actionType == "Attack Error") {
      _handleAssistLog(name, team, isHomeTeam, actionType, phase);
    }
    
    // Use pop instead of popUntil to avoid web routing issues
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleAceSelection(String sName, String? sId, String sTeam, bool isHome, String serveType) {
    String r1Name = isHome ? p1AwayName : p1HomeName;
    String r2Name = isHome ? p2AwayName : p2HomeName;
    String? r1Id = isHome ? p1AwayId : p1HomeId;
    String? r2Id = isHome ? p2AwayId : p2HomeId;
    String rTeam = isHome ? awayTeamName : homeTeamName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hvem bommet på mottak?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: () => _registerAceComplex(sName, sId, sTeam, isHome, r1Name, r1Id, rTeam, serveType), child: Text(r1Name)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => _registerAceComplex(sName, sId, sTeam, isHome, r2Name, r2Id, rTeam, serveType), child: Text(r2Name)),
            const SizedBox(height: 20),
            TextButton(onPressed: () { if (Navigator.canPop(context)) Navigator.pop(context); }, child: const Text("Avbryt / Tilbake")),
          ],
        ),
      ),
    );
  }

  void _registerAceComplex(String sName, String? sId, String sTeam, bool isHome, String vName, String? vId, String vTeam, String serveType) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk dialog
    _registerStat(sName, sId, sTeam, isHome, "Ace", true, subType: serveType);
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': vName, 'player_id': vId, 'team': vTeam,
      'action': "Reception Error", 'sub_type': serveType, 'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _handleKillSelection(String name, String? id, String team, bool isHomeTeam) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk Action Sheet
    bool isReceiving = (isHomeTeam && servingTeam == 'away') || (!isHomeTeam && servingTeam == 'home');
    
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hvor kom angrepet fra?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: () => _registerKill(name, id, team, isHomeTeam, "Forsvar", c), child: const Text("Forsvar")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => _registerKill(name, id, team, isHomeTeam, "Blokktrekk", c), child: const Text("Blokktrekk")),
            if (isReceiving) ...[
              const SizedBox(height: 10),
              ElevatedButton(onPressed: () => _registerKill(name, id, team, isHomeTeam, "Sideout", c), child: const Text("Sideout")),
            ],
            const SizedBox(height: 20),
            TextButton(onPressed: () { if (Navigator.canPop(c)) Navigator.pop(c); }, child: const Text("Avbryt / Tilbake")),
          ],
        ),
      ),
    );
  }

  void _registerKill(String name, String? id, String team, bool isHomeTeam, String origin, BuildContext dialogContext) {
    if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
    _registerStat(name, id, team, isHomeTeam, "Kill", true, subType: origin);
  }

  void _handleBlockSelection(String name, String? id, String team, bool isHomeTeam) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk Action Sheet
    String oppP1 = isHomeTeam ? p1AwayName : p1HomeName;
    String oppP2 = isHomeTeam ? p2AwayName : p2HomeName;
    String? oppId1 = isHomeTeam ? p1AwayId : p1HomeId;
    String? oppId2 = isHomeTeam ? p2AwayId : p2HomeId;
    String oppTeam = isHomeTeam ? awayTeamName : homeTeamName;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hvem ble blokkert?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: () => _registerBlock(name, id, team, isHomeTeam, oppP1, oppId1, oppTeam, c), child: Text(oppP1)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => _registerBlock(name, id, team, isHomeTeam, oppP2, oppId2, oppTeam, c), child: Text(oppP2)),
            const SizedBox(height: 20),
            TextButton(onPressed: () { if (Navigator.canPop(c)) Navigator.pop(c); }, child: const Text("Avbryt / Tilbake")),
          ],
        ),
      ),
    );
  }

  void _registerBlock(String name, String? id, String team, bool isHomeTeam, String oppName, String? oppId, String oppTeam, BuildContext dialogContext) {
    if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
    _registerStat(name, id, team, isHomeTeam, "Block", true);
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': oppName,
      'player_id': oppId,
      'team': oppTeam,
      'action': "Blocked",
      'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  void _registerOpponentError(bool pointToHome) {
    String teamName = pointToHome ? homeTeamName : awayTeamName;
    _updateServeLogic(pointToHome);
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': "Lag",
      'player_id': null,
      'team': teamName,
      'action': "Opponent Error",
      'point_to': pointToHome ? 'home' : 'away',
      'phase': "Unknown",
      'timestamp': FieldValue.serverTimestamp(),
      'prev_serving_team': servingTeam,
      'prev_server_home_idx': serverHomeIdx,
      'prev_server_away_idx': serverAwayIdx,
    });
  }

  void _showInfoModal() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hvordan bruke appen"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• Trykk på en spiller for å registrere Angrep, Blokk, Ess eller Feil."),
              SizedBox(height: 10),
              Text("• 'Motstanderfeil' gir poeng til laget uten å tildele det til en bestemt spiller."),
              SizedBox(height: 10),
              Text("• Bruk pil-ikonet øverst til venstre for å bytte side på skjermen når lagene bytter side på banen."),
              SizedBox(height: 10),
              Text("• 'Angre siste poeng' fjerner siste poeng og hendelse hvis du gjør en feil."),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { if (Navigator.canPop(c)) Navigator.pop(c); }, child: const Text("Lukk"))
        ],
      ),
    );
  }

  // --- SYSTEM LOGIKK ---

  void _initializeData(Map<String, dynamic> data) {
    homeTeamName = data['team_a_name'] ?? 'Lag A';
    awayTeamName = data['team_b_name'] ?? 'Lag B';
    p1HomeName = data['team_a_p1_name'] ?? "Hjemme 1"; p1HomeId = data['team_a_p1_id']; p1HomeImg = data['team_a_p1_img'];
    p2HomeName = data['team_a_p2_name'] ?? "Hjemme 2"; p2HomeId = data['team_a_p2_id']; p2HomeImg = data['team_a_p2_img'];
    p1AwayName = data['team_b_p1_name'] ?? "Borte 1"; p1AwayId = data['team_b_p1_id']; p1AwayImg = data['team_b_p1_img'];
    p2AwayName = data['team_b_p2_name'] ?? "Borte 2"; p2AwayId = data['team_b_p2_id']; p2AwayImg = data['team_b_p2_img'];
    
    if (data.containsKey('serving_team') && data['serving_team'] != null) {
      servingTeam = data['serving_team'];
      serverHomeIdx = data['server_home_idx'] ?? 1;
      serverAwayIdx = data['server_away_idx'] ?? 1;
      isSetupDone = true;
    } else {
      isSetupDone = false;
    }
    isSwapped = data['is_swapped'] ?? false;
    lastSwappedScore = data['last_swapped_score'] ?? -1;
    homeColorStr = data['home_color'] ?? 'blue';
    awayColorStr = data['away_color'] ?? 'red';
    homeTimeoutsUsed = data['timeouts_home'] ?? 0;
    awayTimeoutsUsed = data['timeouts_away'] ?? 0;
    techTimeoutTaken = data['tech_timeout'] ?? false;
  }

  void _updateServeLogic(bool pointToHome) {
    bool homeWasServing = servingTeam == 'home';
    String nextServingTeam = pointToHome ? 'home' : 'away';
    int nextServerHomeIdx = serverHomeIdx;
    int nextServerAwayIdx = serverAwayIdx;

    if (homeWasServing && !pointToHome) {
      nextServerAwayIdx = (serverAwayIdx == 1) ? 2 : 1;
    } else if (!homeWasServing && pointToHome) {
      nextServerHomeIdx = (serverHomeIdx == 1) ? 2 : 1;
    }

    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'serving_team': nextServingTeam,
      'server_home_idx': nextServerHomeIdx,
      'server_away_idx': nextServerAwayIdx,
    });
  }

  void _handleAssistLog(String name, String team, bool isHomeTeam, String actionType, String phase) {
    String partnerName = isHomeTeam ? (name == p1HomeName ? p2HomeName : p1HomeName) : (name == p1AwayName ? p2AwayName : p1AwayName);
    String? partnerId = isHomeTeam ? (name == p1HomeName ? p2HomeId : p1HomeId) : (name == p1AwayName ? p2AwayId : p1AwayId);

    if (actionType == "Kill") {
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
        'player_name': partnerName, 'player_id': partnerId, 'team': team,
        'action': "Set Assist", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
      });
    }
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').add({
      'player_name': partnerName, 'player_id': partnerId, 'team': team,
      'action': "Set Attempt", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _undoLastAction() async {
    final events = await FirebaseFirestore.instance.collection('matches').doc(widget.matchId).collection('events').orderBy('timestamp', descending: true).limit(5).get();
    if (events.docs.isNotEmpty) {
      final lastEvent = events.docs.first;
      final lastTime = (lastEvent.data()['timestamp'] as Timestamp?)?.toDate();
      
      bool pointRemoved = false;
      
      for (var doc in events.docs) {
        final data = doc.data();
        final time = (data['timestamp'] as Timestamp?)?.toDate();
        if (time != null && lastTime != null && lastTime.difference(time).inSeconds.abs() <= 1) {
          if (!pointRemoved && data['point_to'] != 'none') {
            bool pointHome = data['point_to'] == 'home';
            
            final updateData = <String, dynamic>{
              pointHome ? 'home_score' : 'away_score': FieldValue.increment(-1),
            };
            
            if (data['prev_serving_team'] != null) {
              updateData['serving_team'] = data['prev_serving_team'];
              updateData['server_home_idx'] = data['prev_server_home_idx'];
              updateData['server_away_idx'] = data['prev_server_away_idx'];
            }

            FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update(updateData);
            pointRemoved = true;
          }
          doc.reference.delete();
        }
      }
    }
  }

  // --- STANDARD UI KOMPONENTER ---

  Widget _buildScoreColumn(String team, int score, Color color, int timeouts, bool isHome) {
    return Column(children: [
      Text(team, style: AppText.dispH2(20).copyWith(color: color)),
      Text("$score", style: AppText.dispScore(80).copyWith(color: color)),
      if (timeouts > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: Text("T", style: AppText.uiCta.copyWith(fontSize: 12, color: AppColors.nightInk))),
      const SizedBox(height: 8),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color.withOpacity(0.2), foregroundColor: AppColors.nightInk, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        onPressed: () => _registerOpponentError(isHome),
        child: Text("Motstanderfeil", style: AppText.uiCta.copyWith(fontSize: 12, color: AppColors.nightInk)),
      ),
    ]);
  }

  Widget _buildPlayerButton(String name, String? id, String team, bool isHomeTeam, String? imageUrl, int playerIdx) {
    bool isServing = (isHomeTeam && servingTeam == 'home' && serverHomeIdx == playerIdx) || (!isHomeTeam && servingTeam == 'away' && serverAwayIdx == playerIdx);
    return Expanded(child: SizedBox(width: double.infinity, child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isHomeTeam ? _getColor(homeColorStr).withOpacity(0.2) : _getColor(awayColorStr).withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton), side: isServing ? const BorderSide(color: AppColors.coral, width: 3) : BorderSide.none),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: () => _showActionSheet(name, id, team, isHomeTeam, playerIdx),
      child: Stack(children: [
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(radius: 20, backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null, child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person) : null),
          const SizedBox(height: 4),
          Text(name, style: AppText.uiTitle.copyWith(color: AppColors.nightInk), overflow: TextOverflow.ellipsis),
        ])),
        if (isServing) const Positioned(right: 0, top: 0, child: Icon(Icons.sports_volleyball, color: AppColors.coral, size: 24)),
      ]),
    )));
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return Expanded(child: SizedBox(width: double.infinity, child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: AppText.uiCta.copyWith(fontSize: 12)),
    )));
  }

  // --- SETUP OG REGLER ---

  Widget _buildSetupScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Kampoppsett")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text("1. Hvem starter med serven?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(children: [
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: setupServingTeam == 'home' ? Colors.blue : Colors.grey[200]), onPressed: () => setState(() => setupServingTeam = 'home'), child: Text(homeTeamName))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: setupServingTeam == 'away' ? Colors.red : Colors.grey[200]), onPressed: () => setState(() => setupServingTeam = 'away'), child: Text(awayTeamName))),
        ]),
        const SizedBox(height: 30),
        const Text("2. Hvem server FØRST for hjemmelaget?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        _buildServerSelector(p1HomeName, p2HomeName, setupHomeFirstServer, (val) => setState(() => setupHomeFirstServer = val)),
        const SizedBox(height: 20),
        const Text("3. Hvem server FØRST for bortelaget?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        _buildServerSelector(p1AwayName, p2AwayName, setupAwayFirstServer, (val) => setState(() => setupAwayFirstServer = val)),
        const SizedBox(height: 30),
        const Text("Hvilket lag starter på venstre side?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: !setupStartSwapped ? Colors.blue : Colors.grey[200], foregroundColor: !setupStartSwapped ? Colors.white : Colors.black), onPressed: () => setState(() => setupStartSwapped = false), child: Text(homeTeamName))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: setupStartSwapped ? Colors.red : Colors.grey[200], foregroundColor: setupStartSwapped ? Colors.white : Colors.black), onPressed: () => setState(() => setupStartSwapped = true), child: Text(awayTeamName))),
        ]),
        const SizedBox(height: 30),
        Text("Farge $homeTeamName", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildColorPicker(setupHomeColor, (c) => setState(() => setupHomeColor = c)),
        const SizedBox(height: 20),
        Text("Farge $awayTeamName", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildColorPicker(setupAwayColor, (c) => setState(() => setupAwayColor = c)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: setupServingTeam != null ? _finishSetup : null, child: const Text("START KAMP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      ])),
    );
  }

  Widget _buildColorPicker(String currentColor, Function(String) onColorSelected) {
    List<String> colors = ['blue', 'red', 'green', 'orange', 'purple', 'black', 'yellow'];
    return Wrap(
      spacing: 12,
      children: colors.map((c) => GestureDetector(
        onTap: () => onColorSelected(c),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _getColor(c),
            shape: BoxShape.circle,
            border: Border.all(color: currentColor == c ? Colors.white : Colors.transparent, width: 3)
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildServerSelector(String p1, String p2, int currentVal, Function(int) onSelected) {
    return Row(children: [
      Expanded(child: RadioListTile<int>(title: Text(p1), value: 1, groupValue: currentVal, onChanged: (v) => onSelected(v!))),
      Expanded(child: RadioListTile<int>(title: Text(p2), value: 2, groupValue: currentVal, onChanged: (v) => onSelected(v!))),
    ]);
  }

  void _finishSetup() {
    int fHome = setupHomeFirstServer, fAway = setupAwayFirstServer;
    if (setupServingTeam == 'away') {
      fHome = (fHome == 1) ? 2 : 1;
    } else {
      fAway = (fAway == 1) ? 2 : 1;
    }
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      'serving_team': setupServingTeam, 'server_home_idx': fHome, 'server_away_idx': fAway, 'status': 'live',
      'home_color': setupHomeColor, 'away_color': setupAwayColor,
      'is_swapped': setupStartSwapped,
      'last_swapped_score': -1,
    });
  }

  void _checkGameRules(int home, int away, int set) {
    int sum = home + away;
    if (sum > 0 && sum % ((set == 3) ? 5 : 7) == 0 && lastSwappedScore != sum) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SIDEBYTTE!"), backgroundColor: Colors.orange));
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
        'is_swapped': !isSwapped,
        'last_swapped_score': sum,
      });
    }
    if (set < 3 && sum == 21 && !techTimeoutTaken) { _takeTimeout(true, isTech: true); FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({'tech_timeout': true}); }
    int target = (set == 3) ? 15 : 21;
    if ((home >= target && home >= away + 2) || (away >= target && away >= home + 2)) _showSetWinDialog(home > away ? homeTeamName : awayTeamName, set);
  }

  void _takeTimeout(bool isHome, {bool isTech = false}) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(isTech ? "TEKNISK" : "TIMEOUT"), content: const LinearProgressIndicator(), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Ferdig"))]));
    if (!isTech) FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({isHome ? 'timeouts_home' : 'timeouts_away': 1});
  }

  void _showSetWinDialog(String w, int s) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text("$w vant sett $s!"), actions: [ElevatedButton(onPressed: () { Navigator.pop(c); _finishSet(); }, child: const Text("Neste sett"))]));
  }

  void _finishSet() => FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({'home_score': 0, 'away_score': 0, 'current_set': FieldValue.increment(1), 'timeouts_home': 0, 'timeouts_away': 0, 'tech_timeout': false, 'serving_team': null});

  void _showSideSwitchDialog(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.orange));
}