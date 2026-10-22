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
          color: AppColors.nightSurface0,
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
  bool setWinDialogShowing = false;

  int _lastCheckedHome = -1;
  int _lastCheckedAway = -1;
  int _lastCheckedSet = -1;
  int homeSets = 0;
  int awaySets = 0;

  String? setupServingTeam;
  int setupHomeFirstServer = 1, setupAwayFirstServer = 1;
  String setupHomeColor = 'blue', setupAwayColor = 'red';
  bool setupStartSwapped = false;

  bool isSwapped = false;
  int lastSwappedScore = -1;
  String homeColorStr = 'blue', awayColorStr = 'red';

  DocumentReference<Map<String, dynamic>> get _matchRef =>
      FirebaseFirestore.instance.collection('matches').doc(widget.matchId);

  /// Hver handling i kampen lagres som et eget dokument her.
  CollectionReference<Map<String, dynamic>> get _events => _matchRef.collection('events');

  /// Om spiller [playerIdx] (1 eller 2) på laget har serven nå.
  bool _isServing(bool isHomeTeam, int playerIdx) =>
      (isHomeTeam && servingTeam == 'home' && serverHomeIdx == playerIdx) ||
      (!isHomeTeam && servingTeam == 'away' && serverAwayIdx == playerIdx);

  Color _getColor(String colorStr) {
    switch (colorStr) {
      case 'red': return AppColors.coral;
      case 'blue': return Colors.lightBlueAccent;
      case 'green': return AppColors.green;
      case 'orange': return Colors.orangeAccent;
      case 'purple': return Colors.deepPurpleAccent;
      case 'black': return Colors.white;
      case 'yellow': return Colors.amber;
      default: return AppColors.nightInk3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _matchRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Feil: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) {
          return const Center(child: Text("Kampen finnes ikke.", style: TextStyle(color: Colors.white)));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        _initializeData(data);

        if (!isSetupDone) return _buildSetupScreen();

        final homeScore = data['home_score'] ?? 0;
        final awayScore = data['away_score'] ?? 0;
        final currentSet = data['current_set'] ?? 1;
        homeSets = data['home_sets'] ?? 0;
        awaySets = data['away_sets'] ?? 0;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (homeScore != _lastCheckedHome || awayScore != _lastCheckedAway || currentSet != _lastCheckedSet) {
            _lastCheckedHome = homeScore;
            _lastCheckedAway = awayScore;
            _lastCheckedSet = currentSet;
            _checkGameRules(homeScore, awayScore, currentSet, data);
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
            leading: IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => _matchRef.update({'is_swapped': !isSwapped})),
            actions: [
              IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoModal),
              IconButton(icon: const Icon(Icons.timer), color: _getColor(homeColorStr), onPressed: homeTimeoutsUsed == 0 ? () => _takeTimeout(true) : null),
              IconButton(icon: const Icon(Icons.timer), color: _getColor(awayColorStr), onPressed: awayTimeoutsUsed == 0 ? () => _takeTimeout(false) : null),
            ],
          ),
          body: Column(
            children: [
              _buildScoreboard(homeScore, awayScore),
              const SizedBox(height: 8),
              _buildPlayerArea(),
              _buildUndoButton(),
              const SizedBox(height: 12),
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

    final separator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(":", style: AppText.dispScore(40).copyWith(color: AppColors.nightInk3)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: isSwapped ? [awayCol, separator, homeCol] : [homeCol, separator, awayCol],
      ),
    );
  }

  Widget _buildPlayerArea() {
    // To spillerknapper og «Motstander feil» for ett lag.
    Widget teamColumn(bool isHome) {
      final team = isHome ? homeTeamName : awayTeamName;
      return Expanded(child: Column(children: [
        _buildPlayerButton(isHome ? p1HomeName : p1AwayName, isHome ? p1HomeId : p1AwayId, team, isHome, isHome ? p1HomeImg : p1AwayImg, 1),
        const SizedBox(height: 10),
        _buildPlayerButton(isHome ? p2HomeName : p2AwayName, isHome ? p2HomeId : p2AwayId, team, isHome, isHome ? p2HomeImg : p2AwayImg, 2),
        const SizedBox(height: 10),
        _buildTeamActionButton("Motstander feil", _getColor(isHome ? homeColorStr : awayColorStr), () => _registerOpponentError(isHome)),
      ]));
    }

    final homePlayers = teamColumn(true);
    final awayPlayers = teamColumn(false);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: isSwapped ? [awayPlayers, const SizedBox(width: 16), homePlayers] : [homePlayers, const SizedBox(width: 16), awayPlayers],
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: OutlinedButton.icon(
        onPressed: _undoLastAction,
        icon: const Icon(Icons.undo, size: 20),
        label: const Text("Angre siste poeng"),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.nightInk2, side: BorderSide(color: AppColors.nightInk2.withValues(alpha: 0.3))),
      ),
    );
  }

  // --- STATS OG LOGIKK ---

  void _showActionSheet(String name, String? id, String team, bool isHomeTeam, int playerIdx) {
    final isServer = _isServing(isHomeTeam, playerIdx);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 40),
        decoration: BoxDecoration(
          color: AppColors.nightSurface0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Hva gjorde $name?", style: AppText.dispH2(22).copyWith(color: Colors.white)),
            const SizedBox(height: 4),
            Text("Stilling: $_lastCheckedHome - $_lastCheckedAway", style: AppText.uiBody.copyWith(color: AppColors.nightInk2)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Column(children: [
                  _actionBtn("ANGREP (Kill)", AppColors.coral, () => _handleKillSelection(name, id, team, isHomeTeam)),
                  const SizedBox(height: 12),
                  _actionBtn("BLOKK POENG", AppColors.coral, () => _handleBlockSelection(name, id, team, isHomeTeam)),
                  if (isServer) ...[
                    const SizedBox(height: 12),
                    _actionBtn("SERVE ESS", AppColors.coral, () => _handleAceSelection(name, id, team, isHomeTeam, "Ace")),
                  ],
                ])),
                const SizedBox(width: 16),
                Expanded(child: Column(children: [
                  _actionBtn("ANGREPSFEIL", AppColors.nightSurface2, () => _registerStat(name, id, team, isHomeTeam, "Attack Error", false)),
                  if (isServer) ...[
                    const SizedBox(height: 12),
                    _actionBtn("SERVEFEIL", AppColors.nightSurface2, () => _registerStat(name, id, team, isHomeTeam, "Service Error", false)),
                  ],
                  const SizedBox(height: 12),
                  _actionBtn("TEKNISK / NETT", AppColors.nightSurface2, () => _registerStat(name, id, team, isHomeTeam, "Technical Error", false)),
                ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _registerStat(String name, String? id, String team, bool isHomeTeam, String actionType, bool isPositive, {String? subType, bool shouldPop = true, Map<String, dynamic>? extraData}) {
    bool pointToHome = isPositive ? isHomeTeam : !isHomeTeam;

    // Fasen regnes ut fra hvem som serverte FØR poenget: vinner laget som
    // serverte, er det «Break Point», ellers «Sideout».
    bool wasHomeServing = servingTeam == 'home';
    final phase = pointToHome ? (wasHomeServing ? "Break Point" : "Sideout") : (!wasHomeServing ? "Break Point" : "Sideout");

    _updateServeLogic(pointToHome);

    _matchRef.update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });

    int newHomeScore = _lastCheckedHome + (pointToHome ? 1 : 0);
    int newAwayScore = _lastCheckedAway + (!pointToHome ? 1 : 0);

    Map<String, dynamic> eventData = {
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
      'home_score': newHomeScore,
      'away_score': newAwayScore,
      'set_number': _lastCheckedSet,
    };
    if (extraData != null) {
      eventData.addAll(extraData);
    }
    _events.add(eventData);

    if (actionType == "Kill" || actionType == "Attack Error") {
      _handleAssistLog(name, team, isHomeTeam, actionType, phase);
    }
    
    if (actionType != "Ace" && actionType != "Service Error") {
      _dispatchServeInPlay(phase);
    }
    
    // Use pop instead of popUntil to avoid web routing issues
    if (shouldPop && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Spillerne og navnet på laget som står mot [isHome]-laget.
  ({String p1Name, String? p1Id, String p2Name, String? p2Id, String team}) _opponentsOf(bool isHome) => (
        p1Name: isHome ? p1AwayName : p1HomeName,
        p1Id: isHome ? p1AwayId : p1HomeId,
        p2Name: isHome ? p2AwayName : p2HomeName,
        p2Id: isHome ? p2AwayId : p2HomeId,
        team: isHome ? awayTeamName : homeTeamName,
      );

  /// Dialog med én knapp per valg og «Avbryt / Tilbake» nederst.
  /// Hvert valg får dialogens context, slik at det kan lukke dialogen selv.
  void _showChoiceDialog(String title, List<(String, void Function(BuildContext dialogContext))> choices) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ElevatedButton(onPressed: () => choices[i].$2(c), child: Text(choices[i].$1)),
            ],
            const SizedBox(height: 20),
            TextButton(onPressed: () { if (Navigator.canPop(c)) Navigator.pop(c); }, child: const Text("Avbryt / Tilbake")),
          ],
        ),
      ),
    );
  }

  void _handleAceSelection(String sName, String? sId, String sTeam, bool isHome, String serveType) {
    final opp = _opponentsOf(isHome);
    _showChoiceDialog("Hvem bommet på mottak?", [
      (opp.p1Name, (_) => _registerAceComplex(sName, sId, sTeam, isHome, opp.p1Name, opp.p1Id, opp.team, serveType)),
      (opp.p2Name, (_) => _registerAceComplex(sName, sId, sTeam, isHome, opp.p2Name, opp.p2Id, opp.team, serveType)),
    ]);
  }

  void _registerAceComplex(String sName, String? sId, String sTeam, bool isHome, String vName, String? vId, String vTeam, String serveType) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk dialog
    _registerStat(sName, sId, sTeam, isHome, "Ace", true, subType: serveType, shouldPop: false, extraData: {'victim_name': vName});
    _events.add({
      'player_name': vName, 'player_id': vId, 'team': vTeam,
      'action': "Reception Error", 'sub_type': serveType, 'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
      'is_ace': true,
    });
  }

  void _handleKillSelection(String name, String? id, String team, bool isHomeTeam) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk Action Sheet
    bool isReceiving = (isHomeTeam && servingTeam == 'away') || (!isHomeTeam && servingTeam == 'home');

    _showChoiceDialog("Hvor kom angrepet fra?", [
      ("Forsvar", (c) => _registerKill(name, id, team, isHomeTeam, "Forsvar", c)),
      ("Blokktrekk", (c) => _registerKill(name, id, team, isHomeTeam, "Blokktrekk", c)),
      if (isReceiving) ("Sideout", (c) => _registerKill(name, id, team, isHomeTeam, "Sideout", c)),
    ]);
  }

  void _registerKill(String name, String? id, String team, bool isHomeTeam, String origin, BuildContext dialogContext) {
    if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
    _registerStat(name, id, team, isHomeTeam, "Kill", true, subType: origin, shouldPop: false);
  }

  void _handleBlockSelection(String name, String? id, String team, bool isHomeTeam) {
    if (Navigator.canPop(context)) Navigator.pop(context); // Lukk Action Sheet
    final opp = _opponentsOf(isHomeTeam);
    _showChoiceDialog("Hvem ble blokkert?", [
      (opp.p1Name, (c) => _registerBlock(name, id, team, isHomeTeam, opp.p1Name, opp.p1Id, opp.team, c)),
      (opp.p2Name, (c) => _registerBlock(name, id, team, isHomeTeam, opp.p2Name, opp.p2Id, opp.team, c)),
    ]);
  }

  void _registerBlock(String name, String? id, String team, bool isHomeTeam, String oppName, String? oppId, String oppTeam, BuildContext dialogContext) {
    if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
    _registerStat(name, id, team, isHomeTeam, "Block", true, shouldPop: false, extraData: {'victim_name': oppName});
    _events.add({
      'player_name': oppName,
      'player_id': oppId,
      'team': oppTeam,
      'action': "Blocked",
      'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
      'is_block': true,
    });
  }

  void _registerOpponentError(bool pointToHome) {
    String teamName = pointToHome ? homeTeamName : awayTeamName;
    _updateServeLogic(pointToHome);
    _matchRef.update({
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
    });
    int newHomeScore = _lastCheckedHome + (pointToHome ? 1 : 0);
    int newAwayScore = _lastCheckedAway + (!pointToHome ? 1 : 0);

    _events.add({
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
      'home_score': newHomeScore,
      'away_score': newAwayScore,
      'set_number': _lastCheckedSet,
    });
    
    String phase = pointToHome ? (servingTeam == 'home' ? "Break Point" : "Sideout") : (servingTeam == 'away' ? "Break Point" : "Sideout");
    _dispatchServeInPlay(phase);
  }

  void _dispatchServeInPlay(String phase) {
    String sName = '';
    String? sId;
    String sTeam = servingTeam == 'home' ? homeTeamName : awayTeamName;
    if (servingTeam == 'home') {
      sName = serverHomeIdx == 1 ? p1HomeName : p2HomeName;
      sId = serverHomeIdx == 1 ? p1HomeId : p2HomeId;
    } else {
      sName = serverAwayIdx == 1 ? p1AwayName : p2AwayName;
      sId = serverAwayIdx == 1 ? p1AwayId : p2AwayId;
    }
    _events.add({
      'player_name': sName,
      'player_id': sId,
      'team': sTeam,
      'action': "Serve In Play",
      'point_to': "none",
      'phase': phase,
      'timestamp': FieldValue.serverTimestamp(),
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

    _matchRef.update({
      'serving_team': nextServingTeam,
      'server_home_idx': nextServerHomeIdx,
      'server_away_idx': nextServerAwayIdx,
    });
  }

  void _handleAssistLog(String name, String team, bool isHomeTeam, String actionType, String phase) {
    String partnerName = isHomeTeam ? (name == p1HomeName ? p2HomeName : p1HomeName) : (name == p1AwayName ? p2AwayName : p1AwayName);
    String? partnerId = isHomeTeam ? (name == p1HomeName ? p2HomeId : p1HomeId) : (name == p1AwayName ? p2AwayId : p1AwayId);

    if (actionType == "Kill") {
      _events.add({
        'player_name': partnerName, 'player_id': partnerId, 'team': team,
        'action': "Set Assist", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
      });
    }
    _events.add({
      'player_name': partnerName, 'player_id': partnerId, 'team': team,
      'action': "Set Attempt", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _undoLastAction() async {
    final events = await _events.orderBy('timestamp', descending: true).limit(5).get();
    if (events.docs.isNotEmpty) {
      // Poengtrekk og event-sletting i én batch slik at de skjer atomisk
      final batch = FirebaseFirestore.instance.batch();
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

            batch.update(_matchRef, updateData);
            pointRemoved = true;
          }
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    }
  }

  // --- STANDARD UI KOMPONENTER ---

  Widget _buildScoreColumn(String team, int score, Color color, int timeouts, bool isHome) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.nightSurface1,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(children: [
        Text(team, style: AppText.dispH2(20).copyWith(color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text("$score", style: AppText.dispScore(72).copyWith(height: 1.1)),
        if (timeouts > 0) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(4)), child: Text("TIMEOUT", style: AppText.uiCta.copyWith(fontSize: 10, color: Colors.white))),
      ]),
    ));
  }

  Widget _buildPlayerButton(String name, String? id, String team, bool isHomeTeam, String? imageUrl, int playerIdx) {
    final isServing = _isServing(isHomeTeam, playerIdx);
    Color teamColor = isHomeTeam ? _getColor(homeColorStr) : _getColor(awayColorStr);
    
    return Expanded(child: SizedBox(width: double.infinity, child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.nightSurface1,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton), 
          side: BorderSide(color: isServing ? teamColor : Colors.white.withValues(alpha: 0.05), width: isServing ? 2 : 1)
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      onPressed: () => _showActionSheet(name, id, team, isHomeTeam, playerIdx),
      child: Stack(children: [
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            decoration: BoxDecoration(
               shape: BoxShape.circle,
               boxShadow: isServing ? [BoxShadow(color: teamColor.withValues(alpha: 0.5), blurRadius: 12)] : null,
            ),
            child: CircleAvatar(radius: 24, backgroundColor: AppColors.nightSurface2, backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null, child: (imageUrl == null || imageUrl.isEmpty) ? Icon(Icons.person, color: AppColors.nightInk3) : null),
          ),
          const SizedBox(height: 8),
          Text(name, style: AppText.uiTitle.copyWith(color: AppColors.nightInk, fontSize: 15), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, maxLines: 2),
        ])),
        if (isServing) Positioned(right: 0, top: 0, child: Icon(Icons.sports_volleyball, color: teamColor, size: 20)),
      ]),
    )));
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: AppText.uiCta.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
    ));
  }

  Widget _buildTeamActionButton(String text, Color color, VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onTap,
      child: Text(text, textAlign: TextAlign.center, style: AppText.uiCta.copyWith(fontSize: 14, color: color)),
    ));
  }

  // --- SETUP OG REGLER ---

  Widget _buildSetupScreen() {
    // Overskrift over hvert valg i oppsettet.
    Widget heading(String text) =>
        Text(text, style: AppText.uiTitle.copyWith(fontSize: 16, color: AppColors.nightInk2));

    // To knapper side om side der den valgte lyser opp i [color].
    Widget choiceRow(Color color, bool homeSelected, bool awaySelected, VoidCallback onHome, VoidCallback onAway) {
      Widget choice(String label, bool selected, VoidCallback onPressed) => Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? color : AppColors.nightSurface1,
                foregroundColor: Colors.white,
                elevation: selected ? 8 : 0,
                shadowColor: color.withValues(alpha: 0.5),
              ),
              onPressed: onPressed,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          );
      return Row(children: [
        choice(homeTeamName, homeSelected, onHome),
        const SizedBox(width: 12),
        choice(awayTeamName, awaySelected, onAway),
      ]);
    }

    // Velger for hvem av de to spillerne som server først.
    Widget serverBox(String p1, String p2, int current, ValueChanged<int> onSelected) => Container(
          decoration: BoxDecoration(color: AppColors.nightSurface1, borderRadius: BorderRadius.circular(16)),
          child: _buildServerSelector(p1, p2, current, onSelected),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Kampoppsett")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        heading("1. Hvem starter med serven?"),
        const SizedBox(height: 12),
        choiceRow(AppColors.coral, setupServingTeam == 'home', setupServingTeam == 'away',
            () => setState(() => setupServingTeam = 'home'), () => setState(() => setupServingTeam = 'away')),
        const SizedBox(height: 32),
        heading("2. Første server (Hjemme)"),
        const SizedBox(height: 8),
        serverBox(p1HomeName, p2HomeName, setupHomeFirstServer, (val) => setState(() => setupHomeFirstServer = val)),
        const SizedBox(height: 24),
        heading("3. Første server (Borte)"),
        const SizedBox(height: 8),
        serverBox(p1AwayName, p2AwayName, setupAwayFirstServer, (val) => setState(() => setupAwayFirstServer = val)),
        const SizedBox(height: 32),
        heading("Lag på venstre side"),
        const SizedBox(height: 12),
        choiceRow(AppColors.blue, !setupStartSwapped, setupStartSwapped,
            () => setState(() => setupStartSwapped = false), () => setState(() => setupStartSwapped = true)),
        const SizedBox(height: 32),
        heading("Farge $homeTeamName"),
        const SizedBox(height: 12),
        _buildColorPicker(setupHomeColor, (c) => setState(() => setupHomeColor = c)),
        const SizedBox(height: 24),
        heading("Farge $awayTeamName"),
        const SizedBox(height: 12),
        _buildColorPicker(setupAwayColor, (c) => setState(() => setupAwayColor = c)),
        const SizedBox(height: 48),
        ElevatedButton(onPressed: setupServingTeam != null ? _finishSetup : null, child: const Text("START KAMP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2))),
        const SizedBox(height: 24),
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
    _matchRef.update({
      'serving_team': setupServingTeam, 'server_home_idx': fHome, 'server_away_idx': fAway, 'status': 'live',
      'home_color': setupHomeColor, 'away_color': setupAwayColor,
      'is_swapped': setupStartSwapped,
      'last_swapped_score': -1,
    });
  }

  void _checkGameRules(int home, int away, int set, Map<String, dynamic> matchData) {
    int sum = home + away;
    if (sum > 0 && sum % ((set == 3) ? 5 : 7) == 0 && lastSwappedScore != sum) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SIDEBYTTE!"), backgroundColor: Colors.orange));
      _matchRef.update({
        'is_swapped': !isSwapped,
        'last_swapped_score': sum,
      });
    }
    if (set < 3 && sum == 21 && !techTimeoutTaken) { _takeTimeout(true, isTech: true); _matchRef.update({'tech_timeout': true}); }
    int target = (set == 3) ? 15 : 21;
    if ((home >= target && home >= away + 2) || (away >= target && away >= home + 2)) {
       bool isHomeWin = home > away;
       _showSetWinDialog(isHomeWin ? homeTeamName : awayTeamName, set, isHomeWin, matchData);
    }
  }

  void _takeTimeout(bool isHome, {bool isTech = false}) {
    showDialog(context: context, builder: (c) => AlertDialog(title: Text(isTech ? "TEKNISK" : "TIMEOUT"), content: const LinearProgressIndicator(), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Ferdig"))]));
    if (!isTech) _matchRef.update({isHome ? 'timeouts_home' : 'timeouts_away': 1});
    _events.add({
      'player_name': isTech ? "Teknisk Timeout" : "Timeout tatt av ${isHome ? homeTeamName : awayTeamName}",
      'action': "Timeout",
      'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
      'set_number': _lastCheckedSet,
    });
  }

  void _showSetWinDialog(String w, int s, bool isHomeWin, Map<String, dynamic> matchData) {
    // Nye snapshots kan trigge _checkGameRules mens dialogen står åpen –
    // vis aldri to sett-dialoger oppå hverandre (dobbel "Neste sett")
    if (setWinDialogShowing) return;
    setWinDialogShowing = true;
    bool matchWon = (isHomeWin && homeSets == 1) || (!isHomeWin && awaySets == 1);
    
    showDialog(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
      title: Text(matchWon ? "$w vant kampen!" : "$w vant sett $s!"),
      actions: [
        ElevatedButton(
          onPressed: () { 
            Navigator.pop(c); 
            _finishSet(isHomeWin, matchWon, matchData); 
          }, 
          child: Text(matchWon ? "Avslutt kamp" : "Neste sett")
        )
      ]
    )).then((_) => setWinDialogShowing = false);
  }

  void _finishSet(bool isHomeWin, bool matchWon, Map<String, dynamic> matchData) {
    int newHomeSets = isHomeWin ? homeSets + 1 : homeSets;
    int newAwaySets = !isHomeWin ? awaySets + 1 : awaySets;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference matchRef = _matchRef;

    if (matchWon) {
      batch.update(matchRef, {
        'status': 'finished',
        'home_sets': newHomeSets,
        'away_sets': newAwaySets,
        'home_score': newHomeSets, // For legacy support i appen
        'away_score': newAwaySets,
      });

      // --- GRUPPESPILL PLASSERING ---
      String? matchType = matchData['match_type'];
      if (matchType == 'group_final' || matchType == 'group_bronze') {
        String? teamAId = matchData['team_a_id'];
        String? teamBId = matchData['team_b_id'];
        
        if (teamAId != null && teamBId != null) {
          String winnerId = isHomeWin ? teamAId : teamBId;
          String loserId = isHomeWin ? teamBId : teamAId;
          
          int winnerPlacement = matchType == 'group_final' ? 1 : 3;
          int loserPlacement = matchType == 'group_final' ? 2 : 4;
          
          batch.update(FirebaseFirestore.instance.collection('teams').doc(winnerId), {'group_placement': winnerPlacement});
          batch.update(FirebaseFirestore.instance.collection('teams').doc(loserId), {'group_placement': loserPlacement});
        }
      }
    } else {
      batch.update(matchRef, {
        'home_sets': newHomeSets,
        'away_sets': newAwaySets,
        'home_score': 0, 
        'away_score': 0, 
        'current_set': FieldValue.increment(1), 
        'timeouts_home': 0, 
        'timeouts_away': 0, 
        'tech_timeout': false, 
        'serving_team': null
      });
    }

    batch.commit();
  }
}