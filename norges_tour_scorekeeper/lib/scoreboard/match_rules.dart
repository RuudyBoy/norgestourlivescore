part of 'scoreboard_page.dart';

// Kampdata og regler: lese kampdokumentet, sidebytte, timeouts og slutt på sett/kamp.
extension _MatchRules on _ScoreboardPageState {
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

  void _checkGameRules(int home, int away, int set) {
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
       _showSetWinDialog(isHomeWin ? homeTeamName : awayTeamName, set, isHomeWin);
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

  void _showSetWinDialog(String w, int s, bool isHomeWin) {
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
            _finishSet(isHomeWin, matchWon); 
          }, 
          child: Text(matchWon ? "Avslutt kamp" : "Neste sett")
        )
      ]
    )).then((_) => setWinDialogShowing = false);
  }

  void _finishSet(bool isHomeWin, bool matchWon) {
    int newHomeSets = isHomeWin ? homeSets + 1 : homeSets;
    int newAwaySets = !isHomeWin ? awaySets + 1 : awaySets;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference matchRef = _matchRef;

    if (matchWon) {
      batch.update(matchRef, {
        'status': 'finished',
        'home_sets': newHomeSets,
        'away_sets': newAwaySets,
        'home_score': newHomeSets, // Ferdig kamp: score = antall vunne sett (leses av admin og spillerappen)
        'away_score': newAwaySets,
      });
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
