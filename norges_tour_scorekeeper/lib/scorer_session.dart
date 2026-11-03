import 'dart:math';

/// Tilfeldig ID for denne nettleserfanen. Ligger bare i minnet (ikke
/// `localStorage`), så en ny fane får en ny ID. Lagres som `scorer_session`
/// på kampen for å vite hvilken enhet som fører den.
final String scorerSession = _newSessionId();

String _newSessionId() {
  final random = Random.secure();
  return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
