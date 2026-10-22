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
    
    // Bruk pop (ikke popUntil) for å unngå problemer med ruting på web
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
}
