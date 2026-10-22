part of 'scoreboard_page.dart';

// Byggesteiner på poengtavla: stilling, spillerknapper, knapper og infodialog.
extension _ScoreboardWidgets on _ScoreboardPageState {
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
}
