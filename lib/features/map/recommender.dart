import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'graph_algorithms.dart';
import 'map_models.dart';

/// Perfil del usuario usado por el recomendador.
class UserProfile {
  const UserProfile({
    required this.budget,
    required this.remainingKcal,
    required this.mealsLeft,
  });

  final double budget; // MXN disponibles para esta comida
  final double remainingKcal; // kcal que le faltan hoy
  final int mealsLeft; // comidas restantes del día

  /// Meta calórica para UNA comida.
  double get mealTarget =>
      (remainingKcal / math.max(1, mealsLeft)).clamp(250.0, 900.0).toDouble();
}

class FoodRecommendation {
  const FoodRecommendation({
    required this.poi,
    required this.walkMeters,
    required this.score,
    required this.cluster,
    required this.clusterLabel,
    required this.tags,
  });

  final Poi poi;
  final double walkMeters;
  final double score; // menor = mejor
  final int cluster;
  final String clusterLabel;
  final List<String> tags;

  int get walkMinutes => math.max(1, (walkMeters / kWalkMetersPerMin).ceil());
}

class WaterHit {
  const WaterHit(this.poi, this.meters);
  final Poi poi;
  final double meters;
  int get minutes => math.max(1, (meters / kWalkMetersPerMin).ceil());
}

/// Recomendador híbrido:
///  1. Restricción dura de presupuesto (precio <= presupuesto).
///  2. Vector de características normalizado:
///       [distancia caminando (Dijkstra), precio, desvío de kcal, reseña]
///  3. K-Means (k = 3, init determinista farthest-first) agrupa las opciones
///     y etiqueta cada grupo según la calidad de su centroide.
///  4. kNN: se recuperan las k opciones más cercanas al "perfil ideal"
///     (origen del espacio ponderado), penalizando el grupo peor calificado.
class FoodRecommender {
  static const List<double> weights = [0.35, 0.25, 0.25, 0.15];
  static const List<String> _clusterNames = [
    'Mejor ajuste',
    'Buen plan B',
    'Menos ajustado',
  ];

  static List<FoodRecommendation> recommend({
    required Iterable<Poi> candidates,
    required WalkGraph graph,
    required ShortestPaths fromUser,
    required Offset userPosition,
    required UserProfile profile,
    int k = 5,
    int clusters = 3,
  }) {
    final userNode = fromUser.source;
    final userToNode =
        dist2d(userPosition, graph.nodes[userNode]!.position) * kMetersPerPx;

    // 1) Filtro de presupuesto + distancia real de caminata.
    final pois = <Poi>[];
    final walk = <double>[];
    for (final p in candidates) {
      if (p.price > profile.budget) continue;
      final d = fromUser.distanceTo(p.nodeId);
      if (!d.isFinite) continue;
      final access =
          dist2d(p.position, graph.nodes[p.nodeId]!.position) * kMetersPerPx;
      pois.add(p);
      walk.add(userToNode + d + access);
    }
    if (pois.isEmpty) return const [];

    // 2) Características crudas.
    final target = profile.mealTarget;
    final raw = <List<double>>[
      for (var i = 0; i < pois.length; i++)
        [
          walk[i],
          pois[i].price,
          (pois[i].kcal - target).abs() / target,
          5.0 - pois[i].rating,
        ],
    ];
    final norm = _minMaxNormalize(raw);
    final x = [
      for (final row in norm)
        [for (var j = 0; j < row.length; j++) row[j] * weights[j]],
    ];

    // 3) K-Means.
    final kEff = math.min(clusters, pois.length);
    final km = _kMeans(x, kEff);

    // Calidad del centroide = suma de sus componentes ponderadas (menor mejor).
    final quality = [
      for (final c in km.centroids) c.fold(0.0, (a, b) => a + b),
    ];
    final clusterOrder = List<int>.generate(kEff, (i) => i)
      ..sort((a, b) => quality[a].compareTo(quality[b]));
    final clusterRank = {
      for (var r = 0; r < clusterOrder.length; r++) clusterOrder[r]: r,
    };

    // 4) kNN al perfil ideal (origen) + penalización de grupo.
    final scored = <int>[];
    final score = List<double>.filled(pois.length, 0);
    for (var i = 0; i < pois.length; i++) {
      final d = math.sqrt(x[i].fold(0.0, (a, v) => a + v * v));
      final rank = clusterRank[km.assignment[i]] ?? 0;
      final vendorBonus = pois[i].isStudentVendor ? 0.03 : 0.0;
      score[i] = d + rank * 0.05 - vendorBonus;
      scored.add(i);
    }
    scored.sort((a, b) => score[a].compareTo(score[b]));

    final result = <FoodRecommendation>[];
    for (final i in scored.take(k)) {
      final rank = clusterRank[km.assignment[i]] ?? 0;
      result.add(FoodRecommendation(
        poi: pois[i],
        walkMeters: walk[i],
        score: score[i],
        cluster: rank,
        clusterLabel: _clusterNames[math.min(rank, _clusterNames.length - 1)],
        tags: _tags(pois[i], walk[i], profile),
      ));
    }
    return result;
  }

  /// Bebedero más cercano (Dijkstra).
  static WaterHit? nearestWater({
    required Iterable<Poi> waterPois,
    required WalkGraph graph,
    required ShortestPaths fromUser,
    required Offset userPosition,
  }) {
    final userToNode = dist2d(
            userPosition, graph.nodes[fromUser.source]!.position) *
        kMetersPerPx;
    WaterHit? best;
    for (final p in waterPois) {
      final d = fromUser.distanceTo(p.nodeId);
      if (!d.isFinite) continue;
      final access =
          dist2d(p.position, graph.nodes[p.nodeId]!.position) * kMetersPerPx;
      final total = userToNode + d + access;
      if (best == null || total < best.meters) best = WaterHit(p, total);
    }
    return best;
  }

  // -------------------------------------------------------------- utilidades
  static List<String> _tags(Poi p, double meters, UserProfile profile) {
    final tags = <String>[];
    if (meters <= 120) tags.add('Muy cerca');
    if (p.price <= profile.budget * 0.5) tags.add('Muy económico');
    final gap = (p.kcal - profile.mealTarget).abs() / profile.mealTarget;
    if (gap <= 0.2) tags.add('Encaja con tu meta calórica');
    if (p.rating >= 4.5) tags.add('Excelente reseña');
    if (p.isStudentVendor) tags.add('Apoyas a un alumno');
    return tags.take(3).toList();
  }

  static List<List<double>> _minMaxNormalize(List<List<double>> rows) {
    final dims = rows.first.length;
    final mins = List<double>.filled(dims, double.infinity);
    final maxs = List<double>.filled(dims, -double.infinity);
    for (final r in rows) {
      for (var j = 0; j < dims; j++) {
        mins[j] = math.min(mins[j], r[j]);
        maxs[j] = math.max(maxs[j], r[j]);
      }
    }
    return [
      for (final r in rows)
        [
          for (var j = 0; j < dims; j++)
            (maxs[j] - mins[j]).abs() < 1e-9
                ? 0.0
                : (r[j] - mins[j]) / (maxs[j] - mins[j]),
        ],
    ];
  }

  static double _sqDist(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      s += d * d;
    }
    return s;
  }

  static _KMeansResult _kMeans(List<List<double>> pts, int k) {
    final n = pts.length;
    final dims = pts.first.length;

    // Inicialización determinista "farthest-first".
    final centroids = <List<double>>[];
    var first = 0;
    var bestSum = double.infinity;
    for (var i = 0; i < n; i++) {
      final s = pts[i].fold(0.0, (a, b) => a + b);
      if (s < bestSum) {
        bestSum = s;
        first = i;
      }
    }
    centroids.add(List<double>.from(pts[first]));
    while (centroids.length < k) {
      var farIdx = 0;
      var farDist = -1.0;
      for (var i = 0; i < n; i++) {
        var nearest = double.infinity;
        for (final c in centroids) {
          nearest = math.min(nearest, _sqDist(pts[i], c));
        }
        if (nearest > farDist) {
          farDist = nearest;
          farIdx = i;
        }
      }
      centroids.add(List<double>.from(pts[farIdx]));
    }

    final assign = List<int>.filled(n, 0);
    for (var iter = 0; iter < 30; iter++) {
      var changed = false;
      for (var i = 0; i < n; i++) {
        var best = 0;
        var bestD = double.infinity;
        for (var c = 0; c < k; c++) {
          final d = _sqDist(pts[i], centroids[c]);
          if (d < bestD) {
            bestD = d;
            best = c;
          }
        }
        if (assign[i] != best) {
          assign[i] = best;
          changed = true;
        }
      }
      for (var c = 0; c < k; c++) {
        final sum = List<double>.filled(dims, 0);
        var count = 0;
        for (var i = 0; i < n; i++) {
          if (assign[i] != c) continue;
          count++;
          for (var j = 0; j < dims; j++) {
            sum[j] += pts[i][j];
          }
        }
        if (count > 0) {
          for (var j = 0; j < dims; j++) {
            centroids[c][j] = sum[j] / count;
          }
        }
      }
      if (!changed && iter > 0) break;
    }
    return _KMeansResult(assign, centroids);
  }
}

class _KMeansResult {
  _KMeansResult(this.assignment, this.centroids);
  final List<int> assignment;
  final List<List<double>> centroids;
}
