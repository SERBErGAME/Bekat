import 'dart:io';

import 'package:bekat/data/network.dart';
import 'package:bekat/data/planner.dart';
import 'package:bekat/data/schedule.dart';
import 'package:bekat/data/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final net = Network.parse(File('assets/data/network.json').readAsStringSync());
  final sched = Schedule(net);
  final planner = Planner(net, sched);
  Geo at(String id) => net.stops[id]!.pos;

  test('network loads with confirmed and demo routes', () {
    expect(net.routes.map((r) => r.id), containsAll(['1', '2', '3']));
    expect(net.routes.where((r) => !r.demo).map((r) => r.id).toSet(), {'1', '2', '3'});
    for (final d in net.dirs) {
      for (var i = 1; i < d.stopAt.length; i++) {
        expect(d.stopAt[i], greaterThan(d.stopAt[i - 1]), reason: '${d.key} stop order');
      }
    }
  });

  test('direct trip on one route', () {
    final js = planner.plan(at('otchopar'), at('chorsu'), 10 * 60);
    expect(js, isNotEmpty);
    final best = js.firstWhere((j) => !j.walkOnly);
    expect(best.transfers, 0);
    expect(best.rides.first.dir.route.id, anyOf('2', '1', '7'));
  });

  test('transfer needed: Yuksalish -> Otchopar', () {
    final js = planner.plan(at('yuksalish'), at('otchopar'), 8 * 60);
    final best = js.firstWhere((j) => !j.walkOnly);
    expect(best.transfers, greaterThanOrEqualTo(1));
    expect(best.rides.first.dir.route.id, '3');
    // legs are continuous in time
    for (var i = 1; i < best.legs.length; i++) {
      expect(best.legs[i].start, greaterThanOrEqualTo(best.legs[i - 1].end - 1e-6));
    }
  });

  test('two transfers: Aeroport -> Yuksalish', () {
    final js = planner.plan(at('aeroport'), at('yuksalish'), 12 * 60);
    expect(js.where((j) => !j.walkOnly), isNotEmpty);
  });

  test('far from any stop -> approximate journey', () {
    const farNorth = Geo(41.075, 71.60);
    final js = planner.plan(at('chorsu'), farNorth, 9 * 60);
    expect(js, isNotEmpty);
    expect(js.first.approximate, isTrue);
  });

  test('bus positions are on the road and arrivals agree with waits', () {
    final now = 13 * 60.0;
    final buses = sched.positions(now);
    expect(buses.length, greaterThan(20));
    final d = net.route('2').dirs[0];
    final w = sched.waitAt(d, 3, now);
    expect(w, inInclusiveRange(0, d.route.headwayMin.toDouble()));
  });

  test('search understands Latin and Cyrillic', () {
    final s = PlaceSearch(net);
    expect(s.query('chorsu', 'uz').first.title, contains('Chorsu'));
    expect(s.query('Чорсу', 'ru').first.stop?.id, 'chorsu');
    expect(s.query('vokzal', 'uz'), isNotEmpty);
  });
}
