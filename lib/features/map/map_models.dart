import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tamaño del plano (coordenadas del mapa = píxeles del plano de referencia).
const Size kMapSize = Size(975, 882);

/// Escala aproximada del plano. Calibrar con medidas reales del campus.
const double kMetersPerPx = 1.0;

/// Velocidad promedio caminando (~4.5 km/h).
const double kWalkMetersPerMin = 75;

enum PoiType { comida, emprendedor, agua, servicio }

extension PoiTypeX on PoiType {
  String get label {
    switch (this) {
      case PoiType.comida:
        return 'Comida';
      case PoiType.emprendedor:
        return 'Emprendedores';
      case PoiType.agua:
        return 'Hidratación';
      case PoiType.servicio:
        return 'Servicios';
    }
  }

  IconData get icon {
    switch (this) {
      case PoiType.comida:
        return Icons.restaurant_rounded;
      case PoiType.emprendedor:
        return Icons.storefront_rounded;
      case PoiType.agua:
        return Icons.water_drop_rounded;
      case PoiType.servicio:
        return Icons.local_library_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PoiType.comida:
        return const Color(0xFFF2851D);
      case PoiType.emprendedor:
        return const Color(0xFFFF6B6B);
      case PoiType.agua:
        return const Color(0xFF12C4F0);
      case PoiType.servicio:
        return const Color(0xFFB39DDB);
    }
  }
}

/// Punto de interés (comida, vendedor estudiantil, bebedero, servicio).
class Poi {
  const Poi({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.nodeId,
    this.price = 0,
    this.kcal = 0,
    this.rating = 0,
    this.dish = '',
  });

  final String id;
  final String name;
  final PoiType type;
  final Offset position;

  /// Nodo del grafo peatonal por donde se accede al punto.
  final String nodeId;
  final double price; // MXN
  final double kcal; // por porción típica
  final double rating; // 0..5
  final String dish;

  bool get isFood => type == PoiType.comida || type == PoiType.emprendedor;
  bool get isStudentVendor => type == PoiType.emprendedor;
}

/// Nodo del grafo peatonal.
class MapNode {
  const MapNode(this.id, this.position, {this.name});
  final String id;
  final Offset position;
  final String? name;
}

class WalkEdge {
  const WalkEdge(this.a, this.b, this.meters);
  final String a;
  final String b;
  final double meters;
}

/// Edificio / módulo dibujado en el plano.
class MapBuilding {
  const MapBuilding(this.label, this.rect, {this.fontSize = 8});
  final String label;
  final Rect rect;
  final double fontSize;
}

/// Zona grande (CECATI, Prepa, Politécnico...).
class MapZone {
  const MapZone(this.label, this.points, this.color, {this.labelAt});
  final String label;
  final List<Offset> points;
  final Color color;
  final Offset? labelAt;

  Offset get center {
    if (labelAt != null) return labelAt!;
    var x = 0.0, y = 0.0;
    for (final p in points) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / points.length, y / points.length);
  }
}

/// Destino seleccionado (un POI o un edificio).
class Dest {
  const Dest({
    required this.name,
    required this.position,
    required this.nodeId,
    this.poi,
  });
  final String name;
  final Offset position;
  final String nodeId;
  final Poi? poi;
}

double dist2d(Offset a, Offset b) => (a - b).distance;

bool pointInPolygon(Offset p, List<Offset> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i];
    final b = poly[j];
    final crosses = (a.dy > p.dy) != (b.dy > p.dy) &&
        p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx;
    if (crosses) inside = !inside;
  }
  return inside;
}

double distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (len2 == 0) return (p - a).distance;
  var t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
  t = t.clamp(0.0, 1.0).toDouble();
  final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
  return (p - proj).distance;
}

/// Conversión GPS <-> coordenadas del plano.
/// Calibrar [refPixel]/[refLat]/[refLng] con un punto conocido del campus.
class CampusGeo {
  static const Offset refPixel = Offset(330, 450); // zona de módulos O/L
  static const double refLat = 20.6553;
  static const double refLng = -103.3272;

  static double get _mPerDegLat => 111320.0;
  static double get _mPerDegLng =>
      111320.0 * math.cos(refLat * math.pi / 180.0);

  static Offset toMap(double lat, double lng) {
    final dxM = (lng - refLng) * _mPerDegLng;
    final dyM = (lat - refLat) * _mPerDegLat;
    return Offset(
      refPixel.dx + dxM / kMetersPerPx,
      refPixel.dy - dyM / kMetersPerPx,
    );
  }
}
