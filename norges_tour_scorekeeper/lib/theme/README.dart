/// SpikeDunk · Norges Tour
/// Drop these three files into lib/theme/ in your Flutter project.
///
/// pubspec.yaml — add under dependencies:
///   google_fonts: ^6.2.1
///
/// pubspec.yaml — add Google Fonts in your font config (or let
///   google_fonts fetch at runtime — no extra config needed).
///
/// main.dart — apply the theme:
///
/// import 'theme/app_theme.dart';
///
/// MaterialApp(
///   title: 'SpikeDunk',
///   theme:     AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
///   home: const HomePage(),
/// );
///
/// ── Key widget patterns ──────────────────────────────────────
///
/// PRIMARY CTA BUTTON
///   ElevatedButton(
///     onPressed: () {},
///     child: Row(
///       mainAxisAlignment: MainAxisAlignment.center,
///       children: [
///         const Icon(Icons.sports_volleyball, size: 18),
///         const SizedBox(width: 8),
///         Text('Se live', style: AppText.uiCta),
///       ],
///     ),
///   )
///
/// CARD CONTAINER (sand-0 surface, drop-shadow)
///   Container(
///     decoration: BoxDecoration(
///       color: AppColors.sand0,
///       borderRadius: BorderRadius.circular(AppTheme.radiusCard),
///       boxShadow: AppTheme.shadowSm,
///     ),
///     padding: const EdgeInsets.all(AppTheme.cardPad),
///     child: ...,
///   )
///
/// DARK HERO CARD (e.g. live scoreboard)
///   Container(
///     decoration: BoxDecoration(
///       gradient: AppColors.heroNavy,
///       borderRadius: BorderRadius.circular(AppTheme.radiusCard),
///       boxShadow: AppTheme.shadowLg,
///     ),
///   )
///
/// LIVE PILL BADGE
///   Container(
///     padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
///     decoration: BoxDecoration(
///       color: AppColors.coral,
///       borderRadius: BorderRadius.circular(AppTheme.radiusChip),
///     ),
///     child: Text('LIVE', style: AppText.monoSm.copyWith(
///       color: Colors.white, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
///   )
///
/// SECTION KICKER (coral bar + ALL-CAPS label)
///   Row(
///     children: [
///       Container(width: 14, height: 3, color: AppColors.coral,
///         decoration: BoxDecoration(borderRadius: BorderRadius.circular(2))),
///       const SizedBox(width: 8),
///       Text('KAMPPROGRAM', style: AppText.dispKicker()),
///     ],
///   )
///
/// SCORE TEXT (broadcast-size)
///   Text('21', style: AppText.dispScore(46).copyWith(color: Colors.white))
///
/// DATA LABEL (mono ALL-CAPS)
///   Text('SEED 1 · OSLO', style: AppText.monoSm)
///
/// ── Fonts required in pubspec.yaml ───────────────────────────
///   The google_fonts package fetches Saira Condensed, Schibsted
///   Grotesk, and IBM Plex Mono from the internet on first run,
///   then caches them. For offline / production builds, bundle
///   them as assets instead:
///
///   flutter:
///     fonts:
///       - family: SairaCondensed
///         fonts:
///           - asset: assets/fonts/SairaCondensed-ExtraBold.ttf
///             weight: 800
///           - asset: assets/fonts/SairaCondensed-Black.ttf
///             weight: 900
///       - family: SchibstedGrotesk
///         fonts:
///           - asset: assets/fonts/SchibstedGrotesk-Regular.ttf
///             weight: 400
///           - asset: assets/fonts/SchibstedGrotesk-SemiBold.ttf
///             weight: 600
///           - asset: assets/fonts/SchibstedGrotesk-ExtraBold.ttf
///             weight: 800
///       - family: IBMPlexMono
///         fonts:
///           - asset: assets/fonts/IBMPlexMono-Regular.ttf
///             weight: 400
///           - asset: assets/fonts/IBMPlexMono-Medium.ttf
///             weight: 500
