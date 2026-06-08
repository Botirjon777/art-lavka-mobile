import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/core_providers.dart';

/// RU / UZ / EN segmented switcher (SPEC §8 welcome). Updates [localeProvider].
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  static const _labels = {'ru': 'RU', 'uz': 'UZ', 'en': 'EN'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return SegmentedButton<String>(
      segments: [
        for (final code in AppConstants.supportedLanguageCodes)
          ButtonSegment(value: code, label: Text(_labels[code] ?? code)),
      ],
      selected: {current},
      showSelectedIcon: false,
      onSelectionChanged: (sel) =>
          ref.read(localeProvider.notifier).setLanguage(sel.first),
    );
  }
}
