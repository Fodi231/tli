import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'app_log.dart';

/// Language index inside [GeoPlace.names]: en, ru, uk.
int geoLangIndex(String lang) => lang == 'ru' ? 1 : (lang == 'uk' ? 2 : 0);

double _mercX(double lng) => (lng + 180) / 360;
double _mercY(double lat) {
  final s = math.sin(lat.clamp(-85.0, 85.0) * math.pi / 180);
  return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
}

/// A city / town from Natural Earth (public domain).
class GeoPlace {
  final double lng, lat, mx, my;
  final double minZoom;
  final int rank; // label rank, 0 = most important
  final int pop;
  final int country; // index into GeoData.countries, -1 = none
  final int cap; // 1 = national capital, 2 = admin-1 capital, 0 = other
  final List<String> names; // en, ru, uk
  GeoPlace(this.lng, this.lat, this.minZoom, this.rank, this.pop, this.country, this.cap, this.names)
      : mx = _mercX(lng),
        my = _mercY(lat);

  String name(int li) {
    final n = names[li];
    return n.isEmpty ? names[0] : n;
  }
}

class GeoCountry {
  final double lng, lat, mx, my;
  final double minLabel, maxLabel;
  final int rank;
  final List<String> names; // en, ru, uk
  GeoCountry(this.lng, this.lat, this.minLabel, this.maxLabel, this.rank, this.names)
      : mx = _mercX(lng),
        my = _mercY(lat);

  String name(int li) {
    final n = names[li];
    return n.isEmpty ? names[0] : n;
  }
}

/// One closed ring in normalized Web-Mercator coordinates (0..1).
class GeoRing {
  final Float32List xy; // x0,y0,x1,y1…
  final double minX, minY, maxX, maxY;
  GeoRing(this.xy, this.minX, this.minY, this.maxX, this.maxY);
}

/// The whole offline world: countries, ~7 300 places and simplified borders.
/// Loaded once from assets/geo/*.
class GeoData {
  final List<GeoCountry> countries;
  final List<GeoPlace> places; // sorted by importance
  final List<List<GeoRing>> shapes; // per country (same index as [countries])
  GeoData(this.countries, this.places, this.shapes);

  static GeoData? _i;
  static Future<GeoData>? _loading;
  static GeoData? get instance => _i;

  static Future<GeoData> ensure() async {
    final have = _i;
    if (have != null) return have;
    try {
      final d = await (_loading ??= _load());
      if (_i == null) {
        _i = d;
        AppLog.I.info('map', 'геоданные: ${d.countries.length} стран, ${d.places.length} городов');
      }
      return d;
    } catch (e) {
      _loading = null;
      AppLog.I.error('map', 'не удалось загрузить геоданные: $e');
      rethrow;
    }
  }

  static double _d(String s) => double.tryParse(s) ?? 0;

  static Future<GeoData> _load() async {
    final cTxt = await rootBundle.loadString('assets/geo/countries.txt');
    final pTxt = await rootBundle.loadString('assets/geo/places.txt');
    final sTxt = await rootBundle.loadString('assets/geo/shapes.json');

    final countries = <GeoCountry>[];
    for (final line in const LineSplitter().convert(cTxt)) {
      if (line.trim().isEmpty) continue;
      final f = line.split('\t');
      if (f.length < 8) continue;
      countries.add(GeoCountry(_d(f[0]), _d(f[1]), _d(f[2]), _d(f[3]), int.tryParse(f[4]) ?? 5, [f[5], f[6], f[7]]));
    }

    final places = <GeoPlace>[];
    for (final line in const LineSplitter().convert(pTxt)) {
      if (line.trim().isEmpty) continue;
      final f = line.split('\t');
      if (f.length < 10) continue;
      places.add(GeoPlace(
        _d(f[0]),
        _d(f[1]),
        _d(f[2]),
        int.tryParse(f[3]) ?? 9,
        int.tryParse(f[4]) ?? 0,
        int.tryParse(f[5]) ?? -1,
        int.tryParse(f[6]) ?? 0,
        [f[7], f[8], f[9]],
      ));
    }

    final raw = jsonDecode(sTxt) as List;
    final shapes = <List<GeoRing>>[];
    for (final country in raw) {
      final rings = <GeoRing>[];
      for (final poly in country as List) {
        for (final ring in poly as List) {
          final flat = ring as List;
          final n = flat.length ~/ 2;
          if (n < 3) continue;
          final xy = Float32List(n * 2);
          var minX = 2.0, minY = 2.0, maxX = -1.0, maxY = -1.0;
          for (var i = 0; i < n; i++) {
            final x = _mercX((flat[2 * i] as num) / 100.0);
            final y = _mercY((flat[2 * i + 1] as num) / 100.0);
            xy[2 * i] = x;
            xy[2 * i + 1] = y;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
          rings.add(GeoRing(xy, minX, minY, maxX, maxY));
        }
      }
      shapes.add(rings);
    }
    return GeoData(countries, places, shapes);
  }
}
