import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final t  = tp.current;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.primary.withOpacity(0.25))),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16))),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Choose your vibe', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Personalise your experience', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ]),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: AppTheme.themes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final theme    = AppTheme.themes[i];
                final selected = tp.currentThemeId == theme.id;

                return GestureDetector(
                  onTap: () {
                    if (!selected) {
                      tp.setTheme(theme.id);
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? theme.primary : Colors.white.withOpacity(0.08),
                        width: selected ? 2 : 1)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Stack(children: [
                        // LOCAL asset image — works offline
                        Positioned.fill(
                          child: Image.asset(
                            theme.backgroundImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: theme.card),
                          ),
                        ),
                        Positioned.fill(child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              theme.background.withOpacity(selected ? 0.55 : 0.75),
                              theme.background.withOpacity(0.2),
                            ])))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            Container(width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.primary.withOpacity(0.5), width: 2)),
                              child: Center(child: Text(theme.emoji, style: const TextStyle(fontSize: 22)))),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(theme.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Row(children: [
                                _dot(theme.background),
                                _dot(theme.primary),
                                _dot(theme.card),
                              ]),
                            ])),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? theme.primary : Colors.transparent,
                                border: Border.all(color: selected ? theme.primary : Colors.white24, width: 1.5)),
                              child: selected ? const Icon(Icons.check, size: 14, color: Colors.black) : null),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dot(Color c) => Container(
    margin: const EdgeInsets.only(right: 4),
    width: 14, height: 14,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 0.5)));
}