import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../core/app_state.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../data/search.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.app, this.forOrigin = false});
  final AppState app;
  final bool forOrigin;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  List<Place> _local = [], _online = [];
  Timer? _debounce;

  static const _popular = [
    'chorsu',
    'vokzal',
    'aeroport',
    'namdtu_r',
    'bobur',
    'avtovokzal',
    'namdu',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {
      _local = widget.app.search.query(v, Lang.i.code);
      _online = [];
    });
    _debounce?.cancel();
    if (v.trim().length >= 3 && _local.length < 3) {
      _debounce = Timer(const Duration(milliseconds: 650), () async {
        final r = await widget.app.search.online(v);
        if (mounted && _q.text == v) setState(() => _online = r);
      });
    }
  }

  void _pick(Place p) => Navigator.pop(context, Endpoint(p.title, p.pos));

  @override
  Widget build(BuildContext context) {
    final lang = Lang.i.code;
    final net = widget.app.net;
    final results = [..._local, ..._online];
    return PointerInterceptor(
      child: Guarded(
        child: Scaffold(
          backgroundColor: C.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(29),
                            boxShadow: softShadow(0.08),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: widget.forOrigin ? C.blue : C.coral,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _q,
                                  autofocus: true,
                                  onChanged: _changed,
                                  style: T.h.copyWith(fontSize: 18),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: widget.forOrigin
                                        ? tr('from')
                                        : tr('whereTo'),
                                    hintStyle: T.h.copyWith(
                                      fontSize: 18,
                                      color: C.ink3,
                                    ),
                                  ),
                                ),
                              ),
                              if (_q.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _q.clear();
                                    _changed('');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: C.ink3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_q.text.isEmpty) ...[
                        if (widget.forOrigin)
                          _Row(
                            icon: Icons.my_location_rounded,
                            color: C.blue,
                            title: tr('myPlace'),
                            sub: '',
                            onTap: () => Navigator.pop(
                              context,
                              Endpoint(
                                tr('myPlace'),
                                widget.app.me,
                                isMe: true,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final id in _popular)
                              if (net.stops[id] != null)
                                Press(
                                  onTap: () => Navigator.pop(
                                    context,
                                    Endpoint(
                                      net.stops[id]!.name.of(lang),
                                      net.stops[id]!.pos,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          kindIcon(net.stops[id]!.kind),
                                          size: 18,
                                          color: C.ink2,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          net.stops[id]!.name.of(lang),
                                          style: T.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(child: Text(tr('tapMap'), style: T.cap)),
                      ],
                      for (final p in results)
                        _Row(
                          icon: kindIcon(p.kind),
                          color: p.stop != null ? C.blue : C.ink2,
                          title: p.title,
                          sub: p.subtitle,
                          onTap: () => _pick(p),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Press(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(R.m),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: T.h.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: T.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
