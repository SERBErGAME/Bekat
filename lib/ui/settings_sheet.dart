import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import 'widgets.dart';

Future<void> showSettings(BuildContext context, AppState app) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PointerInterceptor(
        child: Guarded(child: _Settings(app: app)),
      ),
    );

class _Settings extends StatefulWidget {
  const _Settings({required this.app});
  final AppState app;
  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.xl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: C.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const IsoBus(width: 96, color: C.green, number: '3'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bekat', style: T.title),
                      Text(tr('tagline'), style: T.sub),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(tr('language'), style: T.cap),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final c in Lang.codes)
                  ButtonSegment(value: c, label: Text(Lang.labels[c]!)),
              ],
              selected: {Lang.i.code},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                Lang.i.set(s.first);
                setState(() {});
              },
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('bigText'), style: T.body),
              value: app.bigText,
              onChanged: (v) {
                app.setBigText(v);
                setState(() {});
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Demo ×10', style: T.body),
              subtitle: Text(tr('estimated'), style: T.cap),
              value: app.speed > 1,
              onChanged: (v) {
                app.setSpeed(v ? 10 : 1);
                setState(() {});
              },
            ),
            const Divider(color: C.line),
            const SizedBox(height: 6),
            Text(tr('about'), style: T.cap),
            const SizedBox(height: 6),
            Text(tr('aboutText'), style: T.sub.copyWith(height: 1.4)),
            const SizedBox(height: 8),
            Text(
              tr('author'),
              style: T.sub.copyWith(color: C.ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
