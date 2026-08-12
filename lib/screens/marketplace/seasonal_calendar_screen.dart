import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class SeasonalCalendarScreen extends StatelessWidget {
  const SeasonalCalendarScreen({super.key});

  static const _calendar = [
    _MonthData('Jan', ['Rohu', 'Catla', 'Hilsa', 'Surmai']),
    _MonthData('Feb', ['Rohu', 'Catla', 'Pomfret', 'Hilsa']),
    _MonthData('Mar', ['Pomfret', 'Surmai', 'Prawn', 'Squid']),
    _MonthData('Apr', ['Surmai', 'Tuna', 'Prawn', 'Snapper']),
    _MonthData('May', ['Tuna', 'Snapper', 'Squid', 'Prawn']),
    _MonthData('Jun', ['⚠️ Ban Season', 'Squid'], isBan: true),
    _MonthData('Jul', ['⚠️ Ban Season'], isBan: true),
    _MonthData('Aug', ['Mackerel', 'Sardine', 'Squid']),
    _MonthData('Sep', ['Mackerel', 'Sardine', 'Pomfret']),
    _MonthData('Oct', ['Pomfret', 'Hilsa', 'Prawn', 'Crab']),
    _MonthData('Nov', ['Hilsa', 'Rohu', 'Prawn', 'Pomfret']),
    _MonthData('Dec', ['Rohu', 'Catla', 'Surmai', 'Crab']),
  ];

  @override
  Widget build(BuildContext context) {
    final t            = Provider.of<ThemeProvider>(context).current;
    final currentMonth = _getMonthAbbr(DateTime.now().month);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.card,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 15),
          ),
        ),
        title: const Row(children: [
          Text('🐟', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Seasonal Fish Calendar',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.05)),
        ),
      ),
      body: Column(children: [

        // Info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.primary.withOpacity(0.20)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: t.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Best catch seasons for Indian coastal waters. '
                    'Jun–Jul is the national fishing ban period.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    height: 1.4),
              ),
            ),
          ]),
        ),

        // Month list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: _calendar.length,
            itemBuilder: (_, i) {
              final entry     = _calendar[i];
              final isCurrent = entry.month == currentMonth;
              final banColor  = const Color(0xFFE57373);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isCurrent ? 16 : 14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? t.primary.withOpacity(0.10)
                      : entry.isBan
                      ? banColor.withOpacity(0.06)
                      : t.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? t.primary.withOpacity(0.55)
                        : entry.isBan
                        ? banColor.withOpacity(0.30)
                        : Colors.white.withOpacity(0.06),
                    width: isCurrent ? 1.5 : 1,
                  ),
                  boxShadow: isCurrent
                      ? [BoxShadow(
                      color: t.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Month label + NOW badge
                    SizedBox(
                      width: 44,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.month,
                              style: TextStyle(
                                color: isCurrent
                                    ? t.primary
                                    : entry.isBan
                                    ? banColor
                                    : Colors.white.withOpacity(0.70),
                                fontSize: 14,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              )),
                          if (isCurrent)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: t.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('NOW',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Fish chips
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.fish.map((fish) {
                          final isBanTag  = fish.contains('Ban');
                          final chipColor = isBanTag
                              ? banColor
                              : isCurrent
                              ? t.primary
                              : const Color(0xFF1D9E75);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: chipColor
                                  .withOpacity(isBanTag ? 0.15 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: chipColor.withOpacity(0.30)),
                            ),
                            child: Text(fish,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: chipColor)),
                          );
                        }).toList(),
                      ),
                    ),

                    // Current month dot
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.circle, color: t.primary, size: 8),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  static String _getMonthAbbr(int month) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return months[month - 1];
  }
}

class _MonthData {
  final String month;
  final List<String> fish;
  final bool isBan;
  const _MonthData(this.month, this.fish, {this.isBan = false});
}