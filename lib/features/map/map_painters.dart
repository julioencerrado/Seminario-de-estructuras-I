import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'campus_data.dart';
import 'graph_algorithms.dart';
import 'map_models.dart';

const Color _landColor = Color(0xFF14243D);
const Color _roadColor = Color(0xFF22375A);
const Color _pathColor = Color(0xFF2E4670);
const Color _buildingColor = Color(0xFF5A6B82);
const Color _courtColor = Color(0xFF1F5A63);

void _drawText(
  Canvas canvas,
  String text,
  Offset center, {
  double fontSize = 9,
  Color color = Colors.white70,
  FontWeight weight = FontWeight.w600,
  double rotation = 0,
  double letterSpacing = 0,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  canvas.save();
  canvas.translate(center.dx, center.dy);
  if (rotation != 0) canvas.rotate(rotation);
  tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  canvas.restore();
}

/// Capa estática: campus, zonas, edificios, andadores y rótulos.
class CampusBasePainter extends CustomPainter {
  const CampusBasePainter(this.graph);
  final WalkGraph graph;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.backgroundDark,
    );

    // Terreno del campus
    final campus = Path()..addPolygon(CampusData.campusOutline, true);
    canvas.drawPath(campus, Paint()..color = _landColor);
    canvas.drawPath(
      campus,
      Paint()
        ..color = const Color(0xFF3A506F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    // Zonas institucionales
    for (final z in CampusData.zones) {
      final path = Path()..addPolygon(z.points, true);
      canvas.drawPath(path, Paint()..color = z.color);
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Canchas
    for (final c in CampusData.courts) {
      final rr = RRect.fromRectAndRadius(c, const Radius.circular(3));
      canvas.drawRRect(rr, Paint()..color = _courtColor);
      final line = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(rr, line);
      canvas.drawLine(Offset(c.left, c.center.dy), Offset(c.right, c.center.dy), line);
      canvas.drawCircle(c.center, math.min(c.width, c.height) * .16, line);
    }

    // Glorieta / anillo vial del estadio
    final ringRect = Rect.fromCenter(
        center: CampusData.stadiumCenter, width: 200, height: 240);
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = _roadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16,
    );

    // Estadio
    final stadium = Rect.fromCenter(
        center: CampusData.stadiumCenter, width: 140, height: 176);
    canvas.drawOval(stadium, Paint()..color = const Color(0xFF3F2A4E));
    canvas.drawOval(
      stadium,
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final field = Rect.fromCenter(
        center: CampusData.stadiumCenter, width: 74, height: 116);
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E6B57),
    );
    canvas.drawLine(Offset(field.left, field.center.dy),
        Offset(field.right, field.center.dy),
        Paint()..color = Colors.white54..strokeWidth = 1);
    canvas.drawCircle(field.center, 10,
        Paint()..color = Colors.white54..style = PaintingStyle.stroke);
    _drawText(canvas, 'ESTADIO', Offset(CampusData.stadiumCenter.dx, stadium.bottom - 12),
        fontSize: 8, color: Colors.white54, letterSpacing: 1.2);

    // Andadores (el mismo grafo que usan Dijkstra y Kruskal)
    for (final e in graph.edges) {
      final a = graph.nodes[e.a]!.position;
      final b = graph.nodes[e.b]!.position;
      final isRoad = _isRoad(e.a) && _isRoad(e.b);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = isRoad ? _roadColor : _pathColor
          ..strokeWidth = isRoad ? 12 : 6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Edificios
    for (final b in CampusData.buildings) {
      final rr = RRect.fromRectAndRadius(b.rect, const Radius.circular(2));
      final isLib = b.label == 'Biblioteca CID';
      canvas.drawRRect(
          rr, Paint()..color = isLib ? const Color(0xFF6E5A8C) : _buildingColor);
      canvas.drawRRect(
        rr,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      _drawText(canvas, b.label, b.rect.center,
          fontSize: b.fontSize, color: Colors.white, weight: FontWeight.w700);
    }

    // Rótulos de zonas
    for (final z in CampusData.zones) {
      if (z.label.isEmpty) continue;
      _drawText(canvas, z.label, z.center,
          fontSize: 9.5, color: Colors.white70, letterSpacing: .8);
    }

    // Nombres de calles
    _drawText(canvas, 'Av. Revolución', const Offset(378, 112),
        fontSize: 10, color: Colors.white38, rotation: .48);
    _drawText(canvas, 'Av. Revolución', const Offset(770, 428),
        fontSize: 10, color: Colors.white38, rotation: .72);
    _drawText(canvas, 'Calzada Olímpica', const Offset(640, 770),
        fontSize: 10, color: Colors.white38, rotation: -.42);
    _drawText(canvas, 'Av. Marcelino García Barragán', const Offset(140, 640),
        fontSize: 10, color: Colors.white38, rotation: 1.12);
    _drawText(canvas, 'Av. Corregidora', const Offset(128, 258),
        fontSize: 10, color: Colors.white38, rotation: -1.0);

    // Entradas
    for (final id in const ['gN', 'gSW', 'gS', 'gE']) {
      final n = graph.nodes[id]!;
      canvas.drawCircle(n.position, 9, Paint()..color = Colors.white);
      canvas.drawCircle(n.position, 9,
          Paint()..color = AppColors.primaryOrange..style = PaintingStyle.stroke..strokeWidth = 2.5);
      final tp = TextPainter(
        text: const TextSpan(
            text: '↔', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, n.position - Offset(tp.width / 2, tp.height / 2));
    }

    // Norte
    final northC = const Offset(60, 60);
    canvas.drawCircle(northC, 22, Paint()..color = Colors.white10);
    final arrow = Path()
      ..moveTo(northC.dx, northC.dy - 16)
      ..lineTo(northC.dx + 8, northC.dy + 10)
      ..lineTo(northC.dx, northC.dy + 5)
      ..lineTo(northC.dx - 8, northC.dy + 10)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Colors.white70);
    _drawText(canvas, 'N', Offset(northC.dx, northC.dy - 30),
        fontSize: 11, color: Colors.white70, weight: FontWeight.w800);
  }

  static bool _isRoad(String id) =>
      id.startsWith('a') || id.startsWith('r') || id == 'q1';

  @override
  bool shouldRepaint(covariant CampusBasePainter old) => false;
}

/// Capa dinámica: rutas, MST de Kruskal, ubicación del usuario y destino.
class CampusOverlayPainter extends CustomPainter {
  CampusOverlayPainter({
    this.route,
    this.tour,
    this.user,
    this.destination,
    this.showMst = true,
  });

  final List<Offset>? route;
  final TourPlan? tour;
  final Offset? user;
  final Offset? destination;
  final bool showMst;

  @override
  void paint(Canvas canvas, Size size) {
    // Árbol de expansión mínima (Kruskal) como líneas punteadas.
    final t = tour;
    if (t != null && showMst) {
      final p = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1.6;
      for (final seg in t.mstSegments) {
        _dashedLine(canvas, seg[0], seg[1], p);
      }
    }

    if (route != null && route!.length > 1) {
      _polyline(canvas, route!, AppColors.primaryOrange);
    }
    if (t != null && t.polyline.length > 1) {
      _polyline(canvas, t.polyline, AppColors.progressTeal);
    }

    if (destination != null) {
      canvas.drawCircle(destination!, 16,
          Paint()..color = AppColors.primaryOrange.withValues(alpha: .25));
      canvas.drawCircle(
        destination!,
        16,
        Paint()
          ..color = AppColors.primaryOrange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    if (user != null) {
      canvas.drawCircle(user!, 22,
          Paint()..color = const Color(0xFF4C8DFF).withValues(alpha: .22));
      canvas.drawCircle(user!, 9, Paint()..color = Colors.white);
      canvas.drawCircle(user!, 6.5, Paint()..color = const Color(0xFF2F6BFF));
    }
  }

  void _polyline(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    const dash = 7.0, gap = 5.0;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CampusOverlayPainter old) => true;
}
