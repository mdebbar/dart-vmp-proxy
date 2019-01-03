import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

import 'evaluation.dart';

Future<bool> _isDartTab(ChromeTab tab) async {
  if (tab.isBackgroundPage ||
      tab.isChromeExtension ||
      tab.url.startsWith('chrome-devtools://')) {
    return false;
  }
  final value =
      await evaluateInTab(tab, 'window.__IS_DART_APP__ ? "yes" : null');
  return value == 'yes';
}

Future<List<ChromeTab>> getDartTabs(ChromeConnection chrome) async {
  final tabs = await chrome.getTabs();
  final dartTabs = <ChromeTab>[];
  final results = await Future.wait(tabs.map(_isDartTab));
  for (var i = 0; i < tabs.length; i++) {
    if (results[i]) {
      dartTabs.add(tabs[i]);
    }
  }
  return dartTabs;
}
