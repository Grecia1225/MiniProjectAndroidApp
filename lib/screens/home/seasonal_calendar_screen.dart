import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/app_localizations.dart';

class SeasonalCalendarScreen extends StatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  State<SeasonalCalendarScreen> createState() => _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState extends State<SeasonalCalendarScreen> {
  // 'key' maps to a fishXxx getter on AppLocalizations — see _fishName().
  static const _fish = [
    {'key': 'rohu',     'peak': [11, 12, 1, 2, 3],    'icon': '🐟', 'color': 0xFF4FC3F7},
    {'key': 'catla',    'peak': [10, 11, 12, 1, 2],   'icon': '🐠', 'color': 0xFF26C6DA},
    {'key': 'hilsa',    'peak': [7, 8, 9, 10],        'icon': '🐡', 'color': 0xFFFFCA28},
    {'key': 'pomfret',  'peak': [10, 11, 12, 1],      'icon': '🐟', 'color': 0xFF80DEEA},
    {'key': 'mackerel', 'peak': [8, 9, 10, 11],       'icon': '🐠', 'color': 0xFF4CAF50},
    {'key': 'sardine',  'peak': [8, 9, 10, 11, 12],   'icon': '🐡', 'color': 0xFF81C784},
    {'key': 'tuna',     'peak': [1, 2, 3, 4, 5],      'icon': '🐟', 'color': 0xFFFF7043},
    {'key': 'prawn',    'peak': [9, 10, 11, 12],      'icon': '🦐', 'color': 0xFFFF8A65},
    {'key': 'lobster',  'peak': [10, 11, 12, 1, 2],   'icon': '🦞', 'color': 0xFFE57373},
    {'key': 'crab',     'peak': [9, 10, 11],          'icon': '🦀', 'color': 0xFFFF6D00},
    {'key': 'surmai',   'peak': [10, 11, 12, 1, 2],   'icon': '🐟', 'color': 0xFFB39DDB},
    {'key': 'squid',    'peak': [11, 12, 1, 2, 3],    'icon': '🦑', 'color': 0xFFCE93D8},
  ];

  late final PageController _pageController;
  late int _pageIndex; // 0 = Jan ... 11 = Dec
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageIndex = _now.month - 1;
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index > 11) return;
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  // Maps a stored fish key to its translated display name.
  // Falls back to English inside AppLocalizations.get() if a locale hasn't
  // defined that fishXxx key yet — see the comment above the fish keys in
  // app_localizations.dart before adding real regional names.
  String _fishName(AppLocalizations loc, String key) {
    switch (key) {
      case 'rohu':     return loc.fishRohu;
      case 'catla':    return loc.fishCatla;
      case 'hilsa':    return loc.fishHilsa;
      case 'pomfret':  return loc.fishPomfret;
      case 'mackerel': return loc.fishMackerel;
      case 'sardine':  return loc.fishSardine;
      case 'tuna':     return loc.fishTuna;
      case 'prawn':    return loc.fishPrawn;
      case 'lobster':  return loc.fishLobster;
      case 'crab':     return loc.fishCrab;
      case 'surmai':   return loc.fishSurmai;
      case 'squid':    return loc.fishSquid;
      default:         return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t     = Provider.of<ThemeProvider>(context).current;
    final loc   = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.primary.withOpacity(0.25))),
                child: Icon(isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 15))),
        title: Text('🐟 ${loc.fishCalendar}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: Column(children: [
        const SizedBox(height: 4),

        // Month header — big name, huge tap targets either side.
        // "Left" arrow always means "earlier in reading order"; which month
        // that maps to is swapped for RTL so it stays intuitive either way.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _arrowButton(
              icon: Icons.chevron_left,
              t: t,
              onTap: () => _goTo(isRtl ? _pageIndex + 1 : _pageIndex - 1),
            ),
            Column(children: [
              Text(
                intl.DateFormat.MMMM(locale).format(DateTime(_now.year, _pageIndex + 1)),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              if (_pageIndex == _now.month - 1) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: t.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(loc.thisMonthBadge,
                      style: TextStyle(color: t.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            _arrowButton(
              icon: Icons.chevron_right,
              t: t,
              onTap: () => _goTo(isRtl ? _pageIndex - 1 : _pageIndex + 1),
            ),
          ]),
        ),

        const SizedBox(height: 10),

        // Quick-jump dots — visual position, minimal reliance on text.
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = i == _pageIndex;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 22 : 8, height: 8,
                  decoration: BoxDecoration(
                      color: selected ? t.primary : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4)),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // One month per page. Only fish that are actually in season this
        // month are shown — nothing to cross-reference, nothing to filter.
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 12,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (context, pageIdx) {
              final monthNum = pageIdx + 1;
              final inSeason = _fish.where((f) => (f['peak'] as List).contains(monthNum)).toList();

              if (inSeason.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🌊', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  Text(loc.noFishThisMonth,
                      style: TextStyle(color: Colors.white.withOpacity(0.5),
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ]));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: inSeason.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final f = inSeason[i];
                  final color = Color(f['color'] as int);
                  return GestureDetector(
                    onTap: () => _showFishDetail(context, f, loc, locale, t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.3))),
                      child: Row(children: [
                        Container(
                          width: 52, height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.15), shape: BoxShape.circle),
                          child: Text(f['icon'] as String, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(_fishName(loc, f['key'] as String),
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                        Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _arrowButton({required IconData icon, required AppTheme t, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: t.card, shape: BoxShape.circle,
            border: Border.all(color: t.primary.withOpacity(0.25))),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }

  void _showFishDetail(BuildContext context, Map f, AppLocalizations loc, String locale, AppTheme t) {
    final peak = List<int>.from(f['peak'] as List)..sort();
    final color = Color(f['color'] as int);
    final peakNames = peak
        .map((m) => intl.DateFormat.MMMM(locale).format(DateTime(DateTime.now().year, m)))
        .join(', ');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: t.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 38, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            Text(f['icon'] as String, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(_fishName(loc, f['key'] as String),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 16),
          Text(loc.peakSeasonLabel, style: TextStyle(color: Colors.white.withOpacity(0.4),
              fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(peakNames, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}