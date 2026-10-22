part of 'scoreboard_page.dart';

// Kampoppsett før første serve: hvem server, første server, side og lagfarger.
extension _SetupScreen on _ScoreboardPageState {
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
            () => _refresh(() => setupServingTeam = 'home'), () => _refresh(() => setupServingTeam = 'away')),
        const SizedBox(height: 32),
        heading("2. Første server (Hjemme)"),
        const SizedBox(height: 8),
        serverBox(p1HomeName, p2HomeName, setupHomeFirstServer, (val) => _refresh(() => setupHomeFirstServer = val)),
        const SizedBox(height: 24),
        heading("3. Første server (Borte)"),
        const SizedBox(height: 8),
        serverBox(p1AwayName, p2AwayName, setupAwayFirstServer, (val) => _refresh(() => setupAwayFirstServer = val)),
        const SizedBox(height: 32),
        heading("Lag på venstre side"),
        const SizedBox(height: 12),
        choiceRow(AppColors.blue, !setupStartSwapped, setupStartSwapped,
            () => _refresh(() => setupStartSwapped = false), () => _refresh(() => setupStartSwapped = true)),
        const SizedBox(height: 32),
        heading("Farge $homeTeamName"),
        const SizedBox(height: 12),
        _buildColorPicker(setupHomeColor, (c) => _refresh(() => setupHomeColor = c)),
        const SizedBox(height: 24),
        heading("Farge $awayTeamName"),
        const SizedBox(height: 12),
        _buildColorPicker(setupAwayColor, (c) => _refresh(() => setupAwayColor = c)),
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
}
