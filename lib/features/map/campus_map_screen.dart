import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import 'campus_data.dart';
import 'graph_algorithms.dart';
import 'map_models.dart';
import 'map_painters.dart';
import 'recommender.dart';

/// Ruta punto a punto calculada con Dijkstra.
class _RoutePlan {
  const _RoutePlan(this.dest, this.points, this.meters);
  final Dest dest;
  final List<Offset> points;
  final double meters;
  int get minutes => math.max(1, (meters / kWalkMetersPerMin).ceil());
}

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({
    super.key,
    this.dailyBudget = 60,
    this.remainingKcal = 1400,
    this.needsWater = false,
  });

  /// Presupuesto para la próxima comida (MXN).
  final double dailyBudget;

  /// Calorías que le faltan al usuario hoy (viene del dashboard).
  final double remainingKcal;

  /// Si el dashboard indica que falta hidratación.
  final bool needsWater;

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen>
    with SingleTickerProviderStateMixin {
  final WalkGraph _graph = CampusData.graph;
  final TransformationController _tc = TransformationController();
  late final AnimationController _fly;
  late final CampusBasePainter _basePainter = CampusBasePainter(_graph);

  Size _viewport = Size.zero;
  bool _fitted = false;

  // Ubicación
  Offset? _user;
  bool _userApprox = false;
  ShortestPaths? _fromUser;
  StreamSubscription<Position>? _gpsSub;
  bool _locating = false;
  bool _marking = false;

  // Perfil
  late double _budget = widget.dailyBudget;
  late double _kcal = widget.remainingKcal;
  late bool _needsWater = widget.needsWater;

  // Filtros
  final Set<PoiType> _visible = {
    PoiType.comida,
    PoiType.emprendedor,
    PoiType.agua,
    PoiType.servicio,
  };

  // Resultados
  List<FoodRecommendation> _recs = const [];
  WaterHit? _water;
  _RoutePlan? _route;
  TourPlan? _tour;
  Dest? _dest;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _fly.dispose();
    _tc.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ cámara
  void _fit() {
    if (_viewport.isEmpty) return;
    final s = math.min(
        _viewport.width / kMapSize.width, _viewport.height / kMapSize.height);
    final tx = (_viewport.width - kMapSize.width * s) / 2;
    final ty = (_viewport.height - kMapSize.height * s) / 2;
    _animateTo(_matrix(s, tx, ty));
  }

  Matrix4 _matrix(double s, double tx, double ty) =>
      Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);

  void _focusOn(Offset p, {double minZoom = 1.4}) {
    if (_viewport.isEmpty) return;
    final s = math.max(_tc.value.getMaxScaleOnAxis(), minZoom);
    _animateTo(_matrix(
        s, _viewport.width / 2 - p.dx * s, _viewport.height / 2 - p.dy * s));
  }

  VoidCallback? _flyTick;

  void _animateTo(Matrix4 target) {
    if (_flyTick != null) _fly.removeListener(_flyTick!);
    final anim = Matrix4Tween(begin: _tc.value, end: target)
        .animate(CurvedAnimation(parent: _fly, curve: Curves.easeInOut));
    _flyTick = () => _tc.value = anim.value;
    _fly
      ..reset()
      ..addListener(_flyTick!);
    _fly.forward();
  }

  // --------------------------------------------------------------- ubicación
  Future<void> _locateWithGps() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _marking = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _toast('Activa el GPS del teléfono o marca tu posición en el mapa.');
        setState(() => _marking = true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Sin permiso de ubicación. Toca el mapa para marcar dónde estás.');
        setState(() => _marking = true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _applyGps(pos, announce: true);
      _startGpsStream();
    } catch (_) {
      _toast('No se pudo obtener el GPS. Toca el mapa para marcar dónde estás.');
      if (mounted) setState(() => _marking = true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _startGpsStream() {
    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 6,
      ),
    ).listen((p) => _applyGps(p), onError: (_) {});
  }

  void _applyGps(Position pos, {bool announce = false}) {
    var p = CampusGeo.toMap(pos.latitude, pos.longitude);
    var approx = false;
    if (!_insideCampus(p)) {
      // Fuera del campus: se ubica en la entrada más cercana.
      approx = true;
      final gates = ['gN', 'gSW', 'gS', 'gE'].map((id) => _graph.nodes[id]!);
      MapNode best = gates.first;
      for (final g in gates) {
        if (dist2d(g.position, p) < dist2d(best.position, p)) best = g;
      }
      p = best.position;
      if (announce) {
        _toast('Estás fuera del campus. Te ubico en: ${best.name}.');
      }
    }
    _setUser(p, approx: approx, focus: announce);
  }

  bool _insideCampus(Offset p) {
    if (pointInPolygon(p, CampusData.campusOutline)) return true;
    final pts = CampusData.campusOutline;
    for (var i = 0; i < pts.length; i++) {
      if (distanceToSegment(p, pts[i], pts[(i + 1) % pts.length]) < 40) {
        return true;
      }
    }
    return false;
  }

  void _setUser(Offset p, {bool approx = false, bool focus = true}) {
    if (!mounted) return;
    setState(() {
      _user = p;
      _userApprox = approx;
      _marking = false;
      _fromUser = _graph.shortestFrom(_graph.nearestNode(p));
      _tour = null;
      _recompute();
      if (_dest != null) _route = _routeTo(_dest!);
    });
    if (focus) _focusOn(p, minZoom: 1.1);
  }

  // ----------------------------------------------------- IA: recomendaciones
  UserProfile get _profile {
    final h = DateTime.now().hour;
    final meals = h < 11 ? 3 : (h < 17 ? 2 : 1);
    return UserProfile(budget: _budget, remainingKcal: _kcal, mealsLeft: meals);
  }

  String get _mealLabel {
    final h = DateTime.now().hour;
    if (h < 11) return 'desayuno';
    if (h < 17) return 'comida';
    return 'cena / snack';
  }

  void _recompute() {
    final user = _user;
    final from = _fromUser;
    if (user == null || from == null) {
      _recs = const [];
      _water = null;
      return;
    }
    _recs = FoodRecommender.recommend(
      candidates: CampusData.foodPois,
      graph: _graph,
      fromUser: from,
      userPosition: user,
      profile: _profile,
    );
    _water = FoodRecommender.nearestWater(
      waterPois: CampusData.waterPois,
      graph: _graph,
      fromUser: from,
      userPosition: user,
    );
  }

  String _placeName(Offset p) {
    for (final b in CampusData.buildings) {
      if (b.rect.inflate(6).contains(p)) return b.label;
    }
    for (final z in CampusData.zones) {
      if (z.label.isNotEmpty && pointInPolygon(p, z.points)) return z.label;
    }
    String best = 'el campus';
    double bestD = 70;
    for (final b in CampusData.buildings) {
      final d = dist2d(b.rect.center, p);
      if (d < bestD) {
        bestD = d;
        best = b.label;
      }
    }
    for (final z in CampusData.zones) {
      if (z.label.isEmpty) continue;
      final d = dist2d(z.center, p);
      if (d < bestD) {
        bestD = d;
        best = z.label;
      }
    }
    return best == 'el campus' || best.contains(' ') || best.length > 3
        ? best
        : 'Módulo $best';
  }

  // -------------------------------------------------------- rutas (Dijkstra)
  _RoutePlan? _routeTo(Dest d) {
    final user = _user;
    final from = _fromUser;
    if (user == null || from == null) return null;
    final ids = from.pathTo(d.nodeId);
    if (ids == null) return null;
    final pts = <Offset>[user, ..._graph.polylineOf(ids), d.position];
    var m = 0.0;
    for (var i = 1; i < pts.length; i++) {
      m += dist2d(pts[i - 1], pts[i]) * kMetersPerPx;
    }
    return _RoutePlan(d, pts, m);
  }

  void _selectDest(Dest d, {bool focus = true}) {
    setState(() {
      _dest = d;
      _tour = null;
      _marking = false;
      _route = _routeTo(d);
    });
    if (focus) _focusOn(d.position, minZoom: 1.2);
  }

  Dest _destFromPoi(Poi p) =>
      Dest(name: p.name, position: p.position, nodeId: p.nodeId, poi: p);

  void _clearSelection() {
    setState(() {
      _dest = null;
      _route = null;
      _tour = null;
      _marking = false;
    });
  }

  bool get _hasSelection =>
      _dest != null || _tour != null || _marking;

  // ------------------------------------------------ recorridos (Kruskal + MST)
  void _startTour(bool hydration) {
    final user = _user;
    final from = _fromUser;
    if (user == null || from == null) {
      _toast('Primero ubícate con el GPS o marcando tu posición.');
      return;
    }
    List<Dest> stops;
    String title;
    if (hydration) {
      final sorted = CampusData.waterPois.toList()
        ..sort((a, b) => from
            .distanceTo(a.nodeId)
            .compareTo(from.distanceTo(b.nodeId)));
      stops = sorted.take(5).map(_destFromPoi).toList();
      title = 'Recorrido de hidratación';
    } else {
      if (_recs.isEmpty) {
        _toast('No hay recomendaciones con tu presupuesto actual.');
        return;
      }
      stops = _recs.take(4).map((r) => _destFromPoi(r.poi)).toList();
      title = 'Recorrido económico';
    }
    final plan = TourPlanner.plan(
      graph: _graph,
      userPosition: user,
      stops: stops,
      title: title,
    );
    if (plan == null) {
      _toast('No se pudo calcular el recorrido.');
      return;
    }
    setState(() {
      _tour = plan;
      _dest = null;
      _route = null;
    });
    _fit();
  }

  // ------------------------------------------------------------- interacción
  void _onMapTap(Offset p) {
    if (_marking) {
      _setUser(p);
      return;
    }
    for (final b in CampusData.buildings) {
      if (b.rect.inflate(4).contains(p)) {
        _selectDest(Dest(
          name: b.label.length <= 3 ? 'Módulo ${b.label}' : b.label,
          position: b.rect.center,
          nodeId: _graph.nearestNode(b.rect.center),
        ));
        return;
      }
    }
    if (_hasSelection) _clearSelection();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  // ------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final maxPanel = MediaQuery.of(context).size.height * 0.38;
    return PopScope(
      canPop: !_hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildChips(),
              Expanded(child: _buildMap()),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxPanel),
                child: _buildPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            tooltip: 'Regresar',
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Mapa CUCEI',
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: 'Presupuesto y metas',
            onPressed: _openProfileSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          for (final t in PoiType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _visible.contains(t),
                showCheckmark: false,
                avatar: Icon(t.icon, size: 16,
                    color: _visible.contains(t) ? Colors.white : t.color),
                label: Text(t.label),
                labelStyle: TextStyle(
                  color: _visible.contains(t) ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white.withValues(alpha: .08),
                selectedColor: t.color.withValues(alpha: .85),
                side: BorderSide.none,
                onSelected: (v) => setState(() {
                  if (v) {
                    _visible.add(t);
                  } else {
                    _visible.remove(t);
                  }
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(builder: (context, c) {
      _viewport = Size(c.maxWidth, c.maxHeight);
      if (!_fitted) {
        _fitted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s = math.min(_viewport.width / kMapSize.width,
              _viewport.height / kMapSize.height);
          _tc.value = _matrix(
            s,
            (_viewport.width - kMapSize.width * s) / 2,
            (_viewport.height - kMapSize.height * s) / 2,
          );
        });
      }
      return ClipRect(
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _tc,
              constrained: false,
              minScale: 0.3,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(240),
              child: SizedBox(
                width: kMapSize.width,
                height: kMapSize.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _onMapTap(d.localPosition),
                  onLongPressStart: (d) => _setUser(d.localPosition),
                  child: Stack(
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          size: kMapSize,
                          painter: _basePainter,
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          size: kMapSize,
                          painter: CampusOverlayPainter(
                            route: _route?.points,
                            tour: _tour,
                            user: _user,
                            destination: _dest?.position,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _tc,
                          builder: (_, __) => _buildMarkers(
                              _tc.value.getMaxScaleOnAxis()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_marking)
              Positioned(
                top: 8,
                left: 12,
                right: 70,
                child: _Banner(
                  icon: Icons.touch_app_rounded,
                  text: 'Toca el mapa donde estás',
                  onClose: () => setState(() => _marking = false),
                ),
              ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _MapButton(
                    icon: _locating
                        ? Icons.hourglass_top_rounded
                        : Icons.my_location_rounded,
                    tooltip: 'Ubicarme con GPS',
                    highlighted: _user != null && !_userApprox,
                    onTap: _locateWithGps,
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.push_pin_rounded,
                    tooltip: 'Marcar dónde estoy',
                    highlighted: _marking,
                    onTap: () => setState(() => _marking = !_marking),
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.alt_route_rounded,
                    tooltip: 'Recorrido inteligente',
                    highlighted: _tour != null,
                    onTap: _openTourSheet,
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.center_focus_strong_rounded,
                    tooltip: 'Ver todo el campus',
                    onTap: _fit,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMarkers(double zoom) {
    final inv = 1 / zoom;
    final rankOf = {
      for (var i = 0; i < _recs.length && i < 3; i++) _recs[i].poi.id: i + 1,
    };
    final tourOrder = {
      if (_tour != null)
        for (var i = 0; i < _tour!.stops.length; i++)
          if (_tour!.stops[i].poi != null) _tour!.stops[i].poi!.id: i + 1,
    };
    final children = <Widget>[];
    for (final p in CampusData.pois) {
      final onTour = tourOrder.containsKey(p.id);
      if (!_visible.contains(p.type) && !onTour) continue;
      final selected = _dest?.poi?.id == p.id;
      children.add(Positioned(
        left: p.position.dx - 22,
        top: p.position.dy - 22,
        width: 44,
        height: 44,
        child: Transform.scale(
          scale: inv,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_marking) {
                _setUser(p.position);
              } else {
                _selectDest(_destFromPoi(p));
              }
            },
            child: Center(
              child: _PoiMarker(
                poi: p,
                selected: selected,
                badge: tourOrder[p.id] ?? rankOf[p.id],
                badgeIsTour: onTour,
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  // ------------------------------------------------------------------- panel
  Widget _buildPanel() {
    Widget content;
    if (_tour != null) {
      content = _buildTourPanel(_tour!);
    } else if (_dest != null) {
      content = _buildDestPanel(_dest!);
    } else if (_marking) {
      content = _panelText(Icons.push_pin_rounded, 'Marca tu posición',
          'Toca cualquier punto del mapa (o mantén presionado) para indicar dónde estás.');
    } else if (_user == null) {
      content = _buildLocatePrompt();
    } else {
      content = _buildRecommendations();
    }
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 12)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: content,
      ),
    );
  }

  Widget _panelText(IconData icon, String title, String body) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(body,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: _clearSelection,
        ),
      ],
    );
  }

  Widget _buildLocatePrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Dónde estás?',
            style: TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Ubícate para recibir recomendaciones de comida económica, '
          'bebederos cercanos y la mejor ruta a pie.',
          style: TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange),
                onPressed: _locateWithGps,
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text('Usar GPS'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38)),
                onPressed: () => setState(() => _marking = true),
                icon: const Icon(Icons.push_pin_rounded, size: 18),
                label: const Text('Marcar en mapa'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    final place = _placeName(_user!);
    final meal = _profile.mealTarget.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_rounded, color: Color(0xFF4C8DFF), size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _userApprox
                    ? 'Cerca de $place (ubicación aproximada)'
                    : 'Estás cerca de $place',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Para tu $_mealLabel: hasta \$${_budget.round()} · ~$meal kcal',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        if (_water != null) ...[
          const SizedBox(height: 10),
          _WaterTile(
            hit: _water!,
            urgent: _needsWater,
            onTap: () => _selectDest(_destFromPoi(_water!.poi)),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.auto_awesome, color: AppColors.primaryOrange, size: 16),
            SizedBox(width: 6),
            Text('Recomendado para ti (IA: kNN + K-Means)',
                style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (_recs.isEmpty)
          Text(
            'Ninguna opción cabe en \$${_budget.round()}. Sube tu presupuesto en ajustes (⚙).',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          )
        else
          for (var i = 0; i < _recs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RecCard(
                rank: i + 1,
                rec: _recs[i],
                onTap: () => _selectDest(_destFromPoi(_recs[i].poi)),
              ),
            ),
      ],
    );
  }

  Widget _buildDestPanel(Dest d) {
    final r = _route;
    final poi = d.poi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: _clearSelection,
            ),
            if (poi != null)
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: poi.type.color, shape: BoxShape.circle),
                child: Icon(poi.type.icon, color: Colors.white, size: 16),
              ),
            Expanded(
              child: Text(d.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (poi != null && poi.isFood) ...[
          const SizedBox(height: 4),
          Text(
            '${poi.dish} · \$${poi.price.round()} · ${poi.kcal.round()} kcal · ★ ${poi.rating}'
            '${poi.isStudentVendor ? ' · Alumno emprendedor' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
        if (poi != null && poi.type == PoiType.agua) ...[
          const SizedBox(height: 4),
          const Text('Punto de hidratación · agua potable gratuita',
              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
        const SizedBox(height: 10),
        if (r != null)
          Row(
            children: [
              _InfoPill(
                  icon: Icons.directions_walk_rounded,
                  text: '${r.meters.round()} m'),
              const SizedBox(width: 8),
              _InfoPill(
                  icon: Icons.timer_outlined, text: '${r.minutes} min'),
              const SizedBox(width: 8),
              const _InfoPill(icon: Icons.route_rounded, text: 'Dijkstra'),
            ],
          )
        else
          Text(
            _user == null
                ? 'Ubícate para calcular la ruta más corta hasta aquí.'
                : 'No hay ruta peatonal disponible.',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (_user == null)
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange),
                  onPressed: _locateWithGps,
                  icon: const Icon(Icons.my_location_rounded, size: 18),
                  label: const Text('Ubicarme'),
                ),
              ),
            if (_user != null)
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38)),
                  onPressed: () => _setUser(d.position, focus: false),
                  icon: const Icon(Icons.push_pin_rounded, size: 18),
                  label: const Text('Estoy aquí'),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white12),
                onPressed: _clearSelection,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cerrar ruta'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTourPanel(TourPlan t) {
    final mins = math.max(1, (t.totalMeters / kWalkMetersPerMin).ceil());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Volver',
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              onPressed: _clearSelection,
            ),
            Expanded(
              child: Text(t.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _InfoPill(
                icon: Icons.directions_walk_rounded,
                text: '${t.totalMeters.round()} m'),
            _InfoPill(icon: Icons.timer_outlined, text: '$mins min'),
            _InfoPill(
                icon: Icons.account_tree_rounded,
                text: 'MST Kruskal ${t.mstMeters.round()} m'),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < t.stops.length; i++)
          InkWell(
            onTap: () => _focusOn(t.stops[i].position),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.progressTeal,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.stops[i].name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13.5)),
                  ),
                  Text('${t.legMeters[i].round()} m',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.white12),
            onPressed: _clearSelection,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cerrar recorrido'),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ sheets
  void _openProfileSheet() {
    var budget = _budget;
    var kcal = _kcal;
    var water = _needsWater;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.secondaryNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                  const Text('Presupuesto y metas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Presupuesto para comer: \$${budget.round()} MXN',
                  style: const TextStyle(color: Colors.white)),
              Slider(
                value: budget,
                min: 10,
                max: 150,
                divisions: 28,
                activeColor: AppColors.primaryOrange,
                onChanged: (v) => setSheet(() => budget = v),
              ),
              Text('Calorías que te faltan hoy: ${kcal.round()} kcal',
                  style: const TextStyle(color: Colors.white)),
              Slider(
                value: kcal,
                min: 300,
                max: 2500,
                divisions: 44,
                activeColor: AppColors.progressYellow,
                onChanged: (v) => setSheet(() => kcal = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF12C4F0),
                title: const Text('Necesito hidratarme',
                    style: TextStyle(color: Colors.white)),
                value: water,
                onChanged: (v) => setSheet(() => water = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() {
                      _budget = budget;
                      _kcal = kcal;
                      _needsWater = water;
                      _tour = null;
                      _recompute();
                    });
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTourSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.secondaryNavy,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
                const Text('Recorrido inteligente',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                'Varias paradas: Kruskal arma la red mínima y define el orden. '
                'Un solo destino: se usa Dijkstra (toca un punto del mapa).',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.water_drop_rounded,
                  color: Color(0xFF12C4F0)),
              title: const Text('Ruta de hidratación',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Los 5 bebederos más cercanos',
                  style: TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.pop(sheetContext);
                _startTour(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings_rounded,
                  color: AppColors.primaryOrange),
              title: const Text('Ruta económica',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Top 4 opciones recomendadas por la IA',
                  style: TextStyle(color: Colors.white60)),
              onTap: () {
                Navigator.pop(sheetContext);
                _startTour(false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ widgets pequeños
class _PoiMarker extends StatelessWidget {
  const _PoiMarker({
    required this.poi,
    required this.selected,
    this.badge,
    this.badgeIsTour = false,
  });

  final Poi poi;
  final bool selected;
  final int? badge;
  final bool badgeIsTour;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 34.0 : 26.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: poi.type.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(poi.type.icon, color: Colors.white, size: selected ? 19 : 15),
        ),
        if (badge != null)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeIsTour
                    ? AppColors.progressTeal
                    : AppColors.progressYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black54, width: 1),
              ),
              child: Text('$badge',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted ? AppColors.primaryOrange : const Color(0xE60A1F3D),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.onClose});
  final IconData icon;
  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Cancelar',
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.progressYellow),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _WaterTile extends StatelessWidget {
  const _WaterTile({required this.hit, required this.urgent, required this.onTap});
  final WaterHit hit;
  final bool urgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF12C4F0);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: blue.withValues(alpha: urgent ? .28 : .14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: blue.withValues(alpha: urgent ? .9 : .4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgent ? '¡Hidrátate! Bebedero más cercano' : 'Bebedero más cercano',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Text(
                    '${hit.poi.name} · ${hit.meters.round()} m · ${hit.minutes} min',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _RecCard extends StatelessWidget {
  const _RecCard({required this.rank, required this.rec, required this.onTap});
  final int rank;
  final FoodRecommendation rec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = rec.poi;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: rank == 1
                  ? AppColors.progressYellow
                  : Colors.white24,
              child: Text('$rank',
                  style: TextStyle(
                      color: rank == 1 ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.dish} · \$${p.price.round()} · ${p.kcal.round()} kcal · ★ ${p.rating}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rec.walkMeters.round()} m · ${rec.walkMinutes} min a pie · ${rec.clusterLabel}',
                    style: const TextStyle(
                        color: AppColors.progressTeal, fontSize: 12),
                  ),
                  if (rec.tags.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in rec.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.type.color.withValues(alpha: .25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10.5)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.directions_walk_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
