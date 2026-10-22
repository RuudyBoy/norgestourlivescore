import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_scorekeeper/theme/app_colors.dart';
import 'package:norges_tour_scorekeeper/theme/app_text_styles.dart';
import 'package:norges_tour_scorekeeper/theme/app_theme.dart';

// Poengtavla for én kamp. Siden og tilstanden ligger her; resten er delt i
// egne filer som `extension` på _ScoreboardPageState.
part 'scoreboard_widgets.dart';
part 'point_registration.dart';
part 'match_rules.dart';
part 'setup_screen.dart';

class ScoreboardPage extends StatefulWidget {
  final String matchId;
  const ScoreboardPage({super.key, required this.matchId});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  // ── Lag og spillere (lest fra kampdokumentet i _initializeData) ──
  String homeTeamName = "Lag A", awayTeamName = "Lag B";
  String p1HomeName = "Hjemme 1", p2HomeName = "Hjemme 2";
  String p1AwayName = "Borte 1", p2AwayName = "Borte 2";
  String? p1HomeId, p2HomeId, p1AwayId, p2AwayId;
  String? p1HomeImg, p2HomeImg, p1AwayImg, p2AwayImg;

  // ── Serve, timeouts og sett ──
  bool isSetupDone = false;
  String servingTeam = "";
  int serverHomeIdx = 1, serverAwayIdx = 1;
  int homeTimeoutsUsed = 0, awayTimeoutsUsed = 0;
  bool techTimeoutTaken = false;
  bool setWinDialogShowing = false;

  // Siste stilling som er sjekket mot reglene (sidebytte, sett ferdig).
  int _lastCheckedHome = -1;
  int _lastCheckedAway = -1;
  int _lastCheckedSet = -1;

  // Vunne sett i kampen.
  int homeSets = 0;
  int awaySets = 0;

  // ── Valg på oppsettskjermen før kampen starter ──
  String? setupServingTeam;
  int setupHomeFirstServer = 1, setupAwayFirstServer = 1;
  String setupHomeColor = 'blue', setupAwayColor = 'red';
  bool setupStartSwapped = false;

  // ── Sidebytte og lagfarger ──
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

  /// `setState` for koden i del-filene. Extensions kan ikke kalle `setState`
  /// direkte fordi den er `@protected`.
  void _refresh(VoidCallback fn) => setState(fn);
}
