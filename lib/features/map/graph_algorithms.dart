import 'dart:ui';

import 'map_models.dart';

/// Resultado de Dijkstra desde un nodo origen.
class ShortestPaths {
  ShortestPaths(this.source, this.dist, this._prev);

  final String source;
  final Map<String, double> dist;
  final Map<String, String> _prev;

  double distanceTo(String id) => dist[id] ?? double.infinity;

  /// Ids de nodos desde [source] hasta [target], o null si no hay camino.
  List<String>? pathTo(String target) {
    if (!dist.containsKey(target) || dist[target] == double.infinity) {
      return null;
    }
    final path = <String>[target];
    var cur = target;
    while (cur != source) {
      final p = _prev[cur];
      if (p == null) return null;
      path.add(p);
      cur = p;
    }
    return path.reversed.toList();
  }
}

/// Conjuntos disjuntos (Union-Find) para Kruskal.
class DisjointSet {
  DisjointSet(int n) : _parent = List<int>.generate(n, (i) => i), _rank = List<int>.filled(n, 0);
  final List<int> _parent;
  final List<int> _rank;

  int find(int x) {
    while (_parent[x] != x) {
      _parent[x] = _parent[_parent[x]];
      x = _parent[x];
    }
    return x;
  }

  bool union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra == rb) return false;
    if (_rank[ra] < _rank[rb]) {
      _parent[ra] = rb;
    } else if (_rank[ra] > _rank[rb]) {
      _parent[rb] = ra;
    } else {
      _parent[rb] = ra;
      _rank[ra]++;
    }
    return true;
  }
}

class WeightedEdge {
  const WeightedEdge(this.u, this.v, this.w);
  final int u;
  final int v;
  final double w;
}

/// Kruskal genérico: devuelve las aristas del árbol de expansión mínima.
List<WeightedEdge> kruskal(int vertexCount, List<WeightedEdge> edges) {
  final sorted = List<WeightedEdge>.from(edges)
    ..sort((a, b) => a.w.compareTo(b.w));
  final ds = DisjointSet(vertexCount);
  final mst = <WeightedEdge>[];
  for (final e in sorted) {
    if (ds.union(e.u, e.v)) {
      mst.add(e);
      if (mst.length == vertexCount - 1) break;
    }
  }
  return mst;
}

/// Grafo peatonal del campus.
class WalkGraph {
  WalkGraph(List<MapNode> nodeList, List<List<String>> links)
      : nodes = {for (final n in nodeList) n.id: n},
        edges = [],
        _adj = {} {
    for (final n in nodeList) {
      _adj[n.id] = [];
    }
    for (final l in links) {
      final a = nodes[l[0]];
      final b = nodes[l[1]];
      assert(a != null && b != null, 'Arista con nodo inexistente: $l');
      if (a == null || b == null) continue;
      final m = dist2d(a.position, b.position) * kMetersPerPx;
      edges.add(WalkEdge(a.id, b.id, m));
      _adj[a.id]!.add(WalkEdge(a.id, b.id, m));
      _adj[b.id]!.add(WalkEdge(b.id, a.id, m));
    }
  }

  final Map<String, MapNode> nodes;
  final List<WalkEdge> edges;
  final Map<String, List<WalkEdge>> _adj;

  /// Nodo más cercano (línea recta) a una posición del plano.
  String nearestNode(Offset p) {
    String best = nodes.keys.first;
    double bestD = double.infinity;
    for (final n in nodes.values) {
      final d = dist2d(n.position, p);
      if (d < bestD) {
        bestD = d;
        best = n.id;
      }
    }
    return best;
  }

  /// Dijkstra O(V²): suficiente para ~60 nodos y sin dependencias externas.
  ShortestPaths shortestFrom(String source) {
    final dist = <String, double>{
      for (final id in nodes.keys) id: double.infinity,
    };
    final prev = <String, String>{};
    final visited = <String>{};
    dist[source] = 0;

    while (true) {
      String? u;
      double best = double.infinity;
      for (final entry in dist.entries) {
        if (!visited.contains(entry.key) && entry.value < best) {
          best = entry.value;
          u = entry.key;
        }
      }
      if (u == null) break;
      visited.add(u);
      for (final e in _adj[u]!) {
        final alt = best + e.meters;
        if (alt < (dist[e.b] ?? double.infinity)) {
          dist[e.b] = alt;
          prev[e.b] = u;
        }
      }
    }
    return ShortestPaths(source, dist, prev);
  }

  List<Offset> polylineOf(List<String> ids) =>
      ids.map((id) => nodes[id]!.position).toList();
}

/// Plan de recorrido multiparada calculado con Kruskal (MST).
class TourPlan {
  TourPlan({
    required this.title,
    required this.stops,
    required this.polyline,
    required this.legMeters,
    required this.mstSegments,
    required this.mstMeters,
  });

  final String title;
  final List<Dest> stops; // en orden de visita
  final List<Offset> polyline; // usuario -> paradas
  final List<double> legMeters;
  final List<List<Offset>> mstSegments; // pares de posiciones del MST
  final double mstMeters;

  double get totalMeters => legMeters.fold(0.0, (a, b) => a + b);
}

class TourPlanner {
  /// 1) Distancias reales (Dijkstra) entre todas las paradas -> grafo completo.
  /// 2) Kruskal obtiene el árbol de expansión mínima (red más corta que
  ///    conecta todas las paradas).
  /// 3) Un recorrido DFS en preorden del MST (visitando primero el hijo más
  ///    cercano) da el orden de visita: aproximación 2x del viajante.
  static TourPlan? plan({
    required WalkGraph graph,
    required Offset userPosition,
    required List<Dest> stops,
    required String title,
  }) {
    if (stops.isEmpty) return null;

    final startNode = graph.nearestNode(userPosition);
    // Índice 0 = usuario; 1..n = paradas.
    final nodeIds = <String>[startNode, ...stops.map((s) => s.nodeId)];
    final n = nodeIds.length;
    final sp = <ShortestPaths>[
      for (final id in nodeIds) graph.shortestFrom(id),
    ];

    final edges = <WeightedEdge>[];
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = sp[i].distanceTo(nodeIds[j]);
        if (d.isFinite) edges.add(WeightedEdge(i, j, d));
      }
    }
    final mst = kruskal(n, edges);
    if (mst.length != n - 1) return null; // grafo no conexo

    final adj = List<List<WeightedEdge>>.generate(n, (_) => []);
    for (final e in mst) {
      adj[e.u].add(e);
      adj[e.v].add(e);
    }

    final order = <int>[];
    final seen = List<bool>.filled(n, false);
    void dfs(int u) {
      seen[u] = true;
      order.add(u);
      final next = List<WeightedEdge>.from(adj[u])
        ..sort((a, b) => a.w.compareTo(b.w));
      for (final e in next) {
        final v = e.u == u ? e.v : e.u;
        if (!seen[v]) dfs(v);
      }
    }

    dfs(0);

    final polyline = <Offset>[userPosition];
    final legs = <double>[];
    var prevIdx = 0;
    var prevPos = userPosition;
    for (final idx in order.skip(1)) {
      final stop = stops[idx - 1];
      final ids = sp[prevIdx].pathTo(nodeIds[idx]);
      if (ids == null) return null;
      final pts = graph.polylineOf(ids);
      var leg = 0.0;
      var cursor = prevPos;
      for (final p in [...pts, stop.position]) {
        leg += dist2d(cursor, p) * kMetersPerPx;
        polyline.add(p);
        cursor = p;
      }
      legs.add(leg);
      prevIdx = idx;
      prevPos = stop.position;
    }

    Offset posOf(int i) => i == 0 ? userPosition : stops[i - 1].position;
    final mstSegments = <List<Offset>>[
      for (final e in mst) [posOf(e.u), posOf(e.v)],
    ];

    return TourPlan(
      title: title,
      stops: [for (final i in order.skip(1)) stops[i - 1]],
      polyline: polyline,
      legMeters: legs,
      mstSegments: mstSegments,
      mstMeters: mst.fold(0.0, (a, e) => a + e.w),
    );
  }
}
