part of 'scoreboard_page.dart';

// Registrering av poeng og handlinger: handlingsmeny, valgdialoger, serverotasjon,
// hendelser til Firestore og «angre siste poeng».
extension _PointRegistration on _ScoreboardPageState {
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

  /// [extraEvents] er tilleggs-events uten poeng (Reception Error, Blocked) som
  /// skal lagres i samme batch som poenget.
  Future<void> _registerStat(String name, String? id, String team, bool isHomeTeam, String actionType, bool isPositive, {String? subType, bool shouldPop = true, Map<String, dynamic>? extraData, List<Map<String, dynamic>> extraEvents = const []}) async {
    // Bruk pop (ikke popUntil) for å unngå problemer med ruting på web
    if (shouldPop && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    if (_busy) return;

    bool pointToHome = isPositive ? isHomeTeam : !isHomeTeam;

    // Fasen regnes ut fra hvem som serverte FØR poenget: vinner laget som
    // serverte, er det «Break Point», ellers «Sideout».
    bool wasHomeServing = servingTeam == 'home';
    final phase = pointToHome ? (wasHomeServing ? "Break Point" : "Sideout") : (!wasHomeServing ? "Break Point" : "Sideout");

    Map<String, dynamic> eventData = {
      'player_name': name,
      'player_id': id,
      'team': team,
      'action': actionType,
      'sub_type': subType,
      'phase': phase,
    };
    if (extraData != null) {
      eventData.addAll(extraData);
    }

    final events = [...extraEvents];
    if (actionType == "Kill" || actionType == "Attack Error") {
      events.addAll(_assistEvents(name, team, isHomeTeam, actionType, phase));
    }
    if (actionType != "Ace" && actionType != "Service Error") {
      events.add(_serveInPlayEvent(phase));
    }

    await _commitPoint(pointToHome, eventData, events);
  }

  /// Skriver poenget, ny serve, poeng-eventet og [extraEvents] i én batch.
  /// Stillingen i eventet regnes ut her, og knappene er låst (`_busy`) til
  /// batchen er lagret, slik at neste trykk alltid ser riktig stilling og serve.
  Future<void> _commitPoint(bool pointToHome, Map<String, dynamic> pointEvent, List<Map<String, dynamic>> extraEvents) async {
    // En annen enhet kan ha tatt over mens handlingsmenyen var åpen.
    if (_viewOnly) return;
    final next = _nextServe(pointToHome);
    final newHomeScore = _lastCheckedHome + (pointToHome ? 1 : 0);
    final newAwayScore = _lastCheckedAway + (!pointToHome ? 1 : 0);
    final setNumber = _lastCheckedSet;

    final batch = FirebaseFirestore.instance.batch();
    batch.update(_matchRef, {
      pointToHome ? 'home_score' : 'away_score': FieldValue.increment(1),
      'serving_team': next.team,
      'server_home_idx': next.homeIdx,
      'server_away_idx': next.awayIdx,
    });
    batch.set(_events.doc(), {
      ...pointEvent,
      'point_to': pointToHome ? 'home' : 'away',
      'timestamp': FieldValue.serverTimestamp(),
      'prev_serving_team': servingTeam,
      'prev_server_home_idx': serverHomeIdx,
      'prev_server_away_idx': serverAwayIdx,
      'home_score': newHomeScore,
      'away_score': newAwayScore,
      'set_number': setNumber,
    });
    for (final event in extraEvents) {
      batch.set(_events.doc(), event);
    }

    _refresh(() => _busy = true);
    bool saved = true;
    try {
      // Uten nett fullføres commit() ikke før nettet er tilbake. Firestore køer
      // skrivingen lokalt, så etter 3 sekunder slippes tavla og vi fortsetter.
      await batch.commit().timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // Skrivingen ligger i køen – fortsett med lokale verdier.
    } catch (e) {
      saved = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kunne ikke lagre poenget: $e"), backgroundColor: AppColors.coral));
      }
    } finally {
      if (mounted) _refresh(() => _busy = false);
    }

    if (!saved || !mounted) return;
    _refresh(() {
      servingTeam = next.team;
      serverHomeIdx = next.homeIdx;
      serverAwayIdx = next.awayIdx;
    });
    _applyScore(newHomeScore, newAwayScore, setNumber);
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
    _registerStat(sName, sId, sTeam, isHome, "Ace", true, subType: serveType, shouldPop: false, extraData: {'victim_name': vName}, extraEvents: [{
      'player_name': vName, 'player_id': vId, 'team': vTeam,
      'action': "Reception Error", 'sub_type': serveType, 'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
      'is_ace': true,
    }]);
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
    _registerStat(name, id, team, isHomeTeam, "Block", true, shouldPop: false, extraData: {'victim_name': oppName}, extraEvents: [{
      'player_name': oppName,
      'player_id': oppId,
      'team': oppTeam,
      'action': "Blocked",
      'point_to': "none",
      'timestamp': FieldValue.serverTimestamp(),
      'is_block': true,
    }]);
  }

  Future<void> _registerOpponentError(bool pointToHome) async {
    if (_busy) return;
    String teamName = pointToHome ? homeTeamName : awayTeamName;
    String phase = pointToHome ? (servingTeam == 'home' ? "Break Point" : "Sideout") : (servingTeam == 'away' ? "Break Point" : "Sideout");

    await _commitPoint(pointToHome, {
      'player_name': "Lag",
      'player_id': null,
      'team': teamName,
      'action': "Opponent Error",
      'phase': "Unknown",
    }, [_serveInPlayEvent(phase)]);
  }

  /// «Serve In Play» for den som serverte ballen (serven FØR poenget).
  Map<String, dynamic> _serveInPlayEvent(String phase) {
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
    return {
      'player_name': sName,
      'player_id': sId,
      'team': sTeam,
      'action': "Serve In Play",
      'point_to': "none",
      'phase': phase,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Serven etter poenget: laget som vant poenget server, og laget som vinner
  /// serven tilbake bytter server.
  ({String team, int homeIdx, int awayIdx}) _nextServe(bool pointToHome) {
    bool homeWasServing = servingTeam == 'home';
    String nextServingTeam = pointToHome ? 'home' : 'away';
    int nextServerHomeIdx = serverHomeIdx;
    int nextServerAwayIdx = serverAwayIdx;

    if (homeWasServing && !pointToHome) {
      nextServerAwayIdx = (serverAwayIdx == 1) ? 2 : 1;
    } else if (!homeWasServing && pointToHome) {
      nextServerHomeIdx = (serverHomeIdx == 1) ? 2 : 1;
    }

    return (team: nextServingTeam, homeIdx: nextServerHomeIdx, awayIdx: nextServerAwayIdx);
  }

  /// «Set Assist» (bare ved Kill) og «Set Attempt» for makkeren.
  List<Map<String, dynamic>> _assistEvents(String name, String team, bool isHomeTeam, String actionType, String phase) {
    String partnerName = isHomeTeam ? (name == p1HomeName ? p2HomeName : p1HomeName) : (name == p1AwayName ? p2AwayName : p1AwayName);
    String? partnerId = isHomeTeam ? (name == p1HomeName ? p2HomeId : p1HomeId) : (name == p1AwayName ? p2AwayId : p1AwayId);

    return [
      if (actionType == "Kill") {
        'player_name': partnerName, 'player_id': partnerId, 'team': team,
        'action': "Set Assist", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'player_name': partnerName, 'player_id': partnerId, 'team': team,
        'action': "Set Attempt", 'point_to': "none", 'phase': phase, 'timestamp': FieldValue.serverTimestamp(),
      },
    ];
  }

  void _showUndoMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: AppColors.coral));
  }

  /// Angrer siste poeng i settet som pågår: trekker fra poenget, setter serven
  /// tilbake og sletter poeng-eventet med tilhørende events (innen 1 sekund).
  /// Ferdige kamper og poeng fra tidligere sett rettes i admin.
  Future<void> _undoLastAction() async {
    if (_busy || _viewOnly) return;
    if (_matchData['status'] == 'finished') {
      _showUndoMessage("Kampen er avsluttet – rett resultatet i admin.");
      return;
    }

    _refresh(() => _busy = true);
    try {
      final events = await _events.orderBy('timestamp', descending: true).limit(10).get();
      final docs = events.docs;

      // Events som ikke er bekreftet av serveren ennå har ikke tidspunkt.
      // Vent til de er lagret i stedet for å angre et eldre poeng.
      final pointIdx = docs.indexWhere((d) => d.data()['point_to'] == 'home' || d.data()['point_to'] == 'away');
      if (pointIdx < 0) {
        _showUndoMessage("Fant ikke noe poeng å angre.");
        return;
      }
      final pointEvent = docs[pointIdx].data();
      final pointTimestamp = pointEvent['timestamp'] as Timestamp?;
      if (docs.first.data()['timestamp'] == null || pointTimestamp == null) {
        _showUndoMessage("Siste poeng lagres fortsatt – prøv igjen om et øyeblikk.");
        return;
      }

      final currentSet = _matchData['current_set'] ?? 1;
      if (pointEvent['set_number'] != currentSet) {
        _showUndoMessage("Kan ikke angre poeng fra forrige sett – rett resultatet i admin.");
        return;
      }

      final pointHome = pointEvent['point_to'] == 'home';
      final teamScore = (_matchData[pointHome ? 'home_score' : 'away_score'] as num?)?.toInt() ?? 0;
      if (teamScore <= 0) {
        _showUndoMessage("Stillingen er allerede 0 – ingenting å angre.");
        return;
      }

      // Poengtrekk og event-sletting i én batch slik at de skjer atomisk
      final batch = FirebaseFirestore.instance.batch();
      final updateData = <String, dynamic>{
        pointHome ? 'home_score' : 'away_score': FieldValue.increment(-1),
      };
      if (pointEvent['prev_serving_team'] != null) {
        updateData['serving_team'] = pointEvent['prev_serving_team'];
        updateData['server_home_idx'] = pointEvent['prev_server_home_idx'];
        updateData['server_away_idx'] = pointEvent['prev_server_away_idx'];
      }
      batch.update(_matchRef, updateData);

      // Poenget og tilleggs-eventene (Serve In Play, Set Assist osv.) har samme
      // tidspunkt, så alt innen 1 sekund av poenget slettes sammen med det.
      // Andre poeng-events slettes aldri, siden bare ett poeng trekkes fra.
      final pointTime = pointTimestamp.toDate();
      for (var i = 0; i < docs.length; i++) {
        final data = docs[i].data();
        final isOtherPoint = i != pointIdx && (data['point_to'] == 'home' || data['point_to'] == 'away');
        final time = (data['timestamp'] as Timestamp?)?.toDate();
        if (!isOtherPoint && time != null && pointTime.difference(time).inSeconds.abs() <= 1) {
          batch.delete(docs[i].reference);
        }
      }

      try {
        await batch.commit().timeout(const Duration(seconds: 3));
      } on TimeoutException {
        // Uten nett: Firestore køer skrivingen lokalt.
      }
    } catch (e) {
      _showUndoMessage("Kunne ikke angre: $e");
    } finally {
      if (mounted) _refresh(() => _busy = false);
    }
  }
}
