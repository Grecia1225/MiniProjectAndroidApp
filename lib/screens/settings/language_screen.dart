import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/utils/app_localizations.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t  = Provider.of<ThemeProvider>(context).current;
    final lp = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary.withOpacity(0.25))),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15),
          ),
        ),
        title: const Text('Language',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Select your preferred language',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 4),
          Text('App text will change immediately',
              style: TextStyle(color: t.primary.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 24),
          ...LanguageProvider.supportedLanguages.map((lang) {
            final selected = lp.locale.languageCode == lang['code'];
            return GestureDetector(
              onTap: () {
                // ── Capture messenger BEFORE setLanguage triggers a rebuild ──
                final messenger = ScaffoldMessenger.of(context);
                final langName  = lang['name']!;

                lp.setLanguage(lang['code']!);

                // ── Snackbar: brief, floating, auto-dismiss in 2s ──
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Row(children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text('Language set to $langName',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                      backgroundColor: t.primary.withOpacity(0.92),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected ? t.primary.withOpacity(0.12) : t.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: selected ? t.primary : Colors.white.withOpacity(0.06),
                      width: selected ? 1.5 : 1),
                  boxShadow: selected
                      ? [BoxShadow(color: t.primary.withOpacity(0.15), blurRadius: 10)]
                      : [],
                ),
                child: Row(children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lang['name']!,
                          style: TextStyle(
                              color: selected ? t.primary : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(lang['native']!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    ]),
                  ),
                  if (selected)
                    Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.black, size: 15))
                  else
                    Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.2)))),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}