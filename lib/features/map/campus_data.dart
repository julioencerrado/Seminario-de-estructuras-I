import 'package:flutter/material.dart';

import 'graph_algorithms.dart';
import 'map_models.dart';

/// Datos del campus CUCEI (plano de referencia 975 x 882).
///
/// NOTA: los comercios, precios, calorías y bebederos son DATOS DE EJEMPLO.
/// Sustituir por la colección de Firestore cuando esté lista (la pantalla
/// solo consume [CampusData.pois], así que basta con cambiar esta fuente).
class CampusData {
  CampusData._();

  // ---------------------------------------------------------------- contorno
  static const List<Offset> campusOutline = [
    Offset(298, 88),
    Offset(360, 140),
    Offset(470, 208),
    Offset(478, 226),
    Offset(925, 585),
    Offset(410, 812),
    Offset(345, 836),
    Offset(300, 826),
    Offset(248, 745),
    Offset(120, 585),
    Offset(45, 428),
    Offset(95, 355),
    Offset(185, 235),
    Offset(222, 190),
  ];

  // ------------------------------------------------------------------- zonas
  static const Color _zone = Color(0xFF4A2F52);
  static const Color _zoneAlt = Color(0xFF5B3560);

  static const List<MapZone> zones = [
    MapZone('CECATI', [
      Offset(292, 94), Offset(336, 122), Offset(306, 214),
      Offset(240, 206), Offset(224, 180),
    ], _zone, labelAt: Offset(278, 165)),
    MapZone('POLITÉCNICO', [
      Offset(332, 228), Offset(460, 228), Offset(460, 350), Offset(332, 350),
    ], _zone, labelAt: Offset(396, 300)),
    MapZone('COLISEO', [
      Offset(484, 272), Offset(546, 272), Offset(546, 338), Offset(484, 338),
    ], _zoneAlt),
    MapZone('PREPA', [
      Offset(48, 424), Offset(72, 386), Offset(118, 380),
      Offset(126, 444), Offset(104, 486), Offset(72, 500),
    ], _zone, labelAt: Offset(82, 420)),
    MapZone('VOCACIONAL', [
      Offset(128, 500), Offset(242, 490), Offset(246, 548),
      Offset(204, 582), Offset(150, 572),
    ], _zone, labelAt: Offset(180, 527)),
    MapZone('', [
      Offset(190, 248), Offset(246, 248), Offset(246, 326), Offset(190, 326),
    ], _zone),
    MapZone('ALBERCA OLÍMPICA', [
      Offset(580, 636), Offset(642, 636), Offset(642, 724), Offset(580, 724),
    ], _zoneAlt, labelAt: Offset(611, 682)),
    MapZone('', [
      Offset(646, 640), Offset(736, 620), Offset(752, 690), Offset(664, 712),
    ], _zoneAlt),
    MapZone('PROULEX', [
      Offset(318, 752), Offset(392, 752), Offset(392, 806), Offset(340, 806),
    ], Color(0xFF8A3E6E), labelAt: Offset(352, 780)),
  ];

  /// Canchas deportivas (rectángulos con marcas de juego).
  static const List<Rect> courts = [
    Rect.fromLTWH(506, 340, 50, 54),
    Rect.fromLTWH(568, 334, 60, 66),
    Rect.fromLTWH(516, 420, 52, 64),
    Rect.fromLTWH(574, 420, 58, 64),
    Rect.fromLTWH(548, 500, 62, 62),
    Rect.fromLTWH(632, 508, 62, 60),
  ];

  static const Offset stadiumCenter = Offset(475, 660);

  // --------------------------------------------------------------- edificios
  static const List<MapBuilding> buildings = [
    MapBuilding('X', Rect.fromLTWH(214, 342, 56, 10)),
    MapBuilding('W', Rect.fromLTWH(214, 356, 56, 10)),
    MapBuilding('V', Rect.fromLTWH(254, 332, 52, 16)),
    MapBuilding('V2', Rect.fromLTWH(254, 352, 60, 20), fontSize: 9),
    MapBuilding('S2', Rect.fromLTWH(256, 376, 20, 14)),
    MapBuilding('U', Rect.fromLTWH(350, 362, 46, 10)),
    MapBuilding('T', Rect.fromLTWH(350, 375, 46, 9)),
    MapBuilding('S', Rect.fromLTWH(260, 402, 44, 16)),
    MapBuilding('R', Rect.fromLTWH(326, 402, 34, 14)),
    MapBuilding('Q', Rect.fromLTWH(364, 405, 78, 14)),
    MapBuilding('P', Rect.fromLTWH(326, 436, 84, 13)),
    MapBuilding('O', Rect.fromLTWH(258, 432, 50, 28), fontSize: 9),
    MapBuilding('N', Rect.fromLTWH(260, 472, 46, 18), fontSize: 9),
    MapBuilding('M', Rect.fromLTWH(260, 500, 50, 18), fontSize: 9),
    MapBuilding('K', Rect.fromLTWH(262, 533, 68, 13)),
    MapBuilding('L2', Rect.fromLTWH(322, 484, 24, 18)),
    MapBuilding('L', Rect.fromLTWH(352, 478, 64, 32), fontSize: 10),
    MapBuilding('UCT 1', Rect.fromLTWH(352, 512, 44, 16)),
    MapBuilding('UCT 2', Rect.fromLTWH(352, 532, 44, 16)),
    MapBuilding('CTA', Rect.fromLTWH(398, 532, 28, 16)),
    MapBuilding('H', Rect.fromLTWH(240, 568, 22, 10)),
    MapBuilding('G', Rect.fromLTWH(178, 581, 54, 14)),
    MapBuilding('F', Rect.fromLTWH(285, 578, 56, 12)),
    MapBuilding('E', Rect.fromLTWH(190, 617, 172, 11)),
    MapBuilding('D', Rect.fromLTWH(328, 731, 36, 11)),
    MapBuilding('Z1', Rect.fromLTWH(140, 428, 16, 12)),
    MapBuilding('Z2', Rect.fromLTWH(122, 428, 16, 12)),
    MapBuilding('Biblioteca CID', Rect.fromLTWH(312, 672, 66, 46), fontSize: 8),
  ];

  // ------------------------------------------------------------ grafo peatonal
  static const List<MapNode> nodes = [
    // Entradas
    MapNode('gN', Offset(470, 205), name: 'Entrada Av. Revolución'),
    MapNode('gSW', Offset(212, 752), name: 'Entrada Av. M. García Barragán'),
    MapNode('gS', Offset(418, 820), name: 'Entrada Calzada Olímpica'),
    MapNode('gE', Offset(800, 690), name: 'Entrada oriente'),
    // Avenida interior
    MapNode('a1', Offset(465, 240)),
    MapNode('a2', Offset(465, 320)),
    MapNode('a3', Offset(465, 400)),
    MapNode('a4', Offset(465, 470)),
    MapNode('a5', Offset(465, 515)),
    // Glorieta del estadio
    MapNode('r1', Offset(475, 540)),
    MapNode('r2', Offset(546, 575)),
    MapNode('r3', Offset(575, 660)),
    MapNode('r4', Offset(546, 745)),
    MapNode('r5', Offset(475, 780)),
    MapNode('r6', Offset(404, 745)),
    MapNode('r7', Offset(375, 660)),
    MapNode('r8', Offset(404, 575)),
    MapNode('q1', Offset(408, 795)),
    MapNode('e1', Offset(690, 675)),
    // Andador central
    MapNode('c1', Offset(318, 262)),
    MapNode('c2', Offset(318, 330)),
    MapNode('c3', Offset(318, 392)),
    MapNode('c4', Offset(318, 455)),
    MapNode('c5', Offset(318, 520)),
    MapNode('c6', Offset(305, 575)),
    MapNode('c7', Offset(300, 622)),
    // Andador oeste
    MapNode('w0', Offset(250, 262)),
    MapNode('w1', Offset(250, 320)),
    MapNode('w2', Offset(250, 392)),
    MapNode('w3', Offset(250, 470)),
    MapNode('w4', Offset(250, 545)),
    MapNode('s0', Offset(250, 600)),
    // Andador este (hacia la avenida)
    MapNode('b1', Offset(440, 330)),
    MapNode('b2', Offset(440, 392)),
    MapNode('b3', Offset(440, 470)),
    MapNode('b4', Offset(440, 520)),
    // Oeste (Prepa / Vocacional)
    MapNode('wl', Offset(185, 455)),
    MapNode('pr', Offset(135, 448)),
    MapNode('vc', Offset(215, 545)),
    // Deportivas
    MapNode('k0', Offset(505, 322)),
    MapNode('k1', Offset(525, 398)),
    MapNode('k2', Offset(585, 470)),
    MapNode('k3', Offset(600, 540)),
    // Sur (CID / PROULEX)
    MapNode('p1', Offset(350, 640)),
    MapNode('s2', Offset(300, 668)),
    MapNode('s3', Offset(290, 705)),
    MapNode('s4', Offset(280, 738)),
    MapNode('s5', Offset(345, 715)),
    MapNode('s6', Offset(365, 782)),
  ];

  static const List<List<String>> links = [
    ['gN', 'a1'], ['a1', 'a2'], ['a2', 'a3'], ['a3', 'a4'], ['a4', 'a5'],
    ['a5', 'r1'],
    ['r1', 'r2'], ['r2', 'r3'], ['r3', 'r4'], ['r4', 'r5'], ['r5', 'r6'],
    ['r6', 'r7'], ['r7', 'r8'], ['r8', 'r1'],
    ['q1', 'gS'], ['q1', 'r6'], ['q1', 'r5'], ['q1', 's6'],
    ['gE', 'e1'], ['e1', 'r3'],
    ['a2', 'b1'], ['a3', 'b2'], ['a4', 'b3'], ['a5', 'b4'],
    ['b1', 'b2'], ['b2', 'b3'], ['b3', 'b4'], ['b4', 'r1'],
    ['c1', 'c2'], ['c2', 'c3'], ['c3', 'c4'], ['c4', 'c5'], ['c5', 'c6'],
    ['c6', 'c7'],
    ['w0', 'w1'], ['w1', 'w2'], ['w2', 'w3'], ['w3', 'w4'], ['w4', 's0'],
    ['w0', 'c1'], ['w1', 'c2'], ['w2', 'c3'], ['w3', 'c4'], ['w4', 'c5'],
    ['c3', 'b2'], ['c4', 'b3'],
    ['s0', 'c7'], ['c7', 'p1'], ['p1', 'r8'], ['p1', 'r7'], ['c7', 's2'],
    ['s2', 'p1'], ['s2', 's3'], ['s3', 's4'], ['s3', 's5'], ['s4', 's5'],
    ['s4', 'gSW'], ['s5', 's6'], ['s5', 'r6'],
    ['w3', 'wl'], ['wl', 'pr'], ['w4', 'vc'],
    ['a2', 'k0'], ['a3', 'k1'], ['k1', 'k2'], ['k2', 'k3'], ['k3', 'r2'],
  ];

  static final WalkGraph graph = WalkGraph(nodes, links);

  // ------------------------------------------------------------------- POIs
  static const List<Poi> pois = [
    // Comida formal
    Poi(id: 'f1', name: 'Área de comida Politécnico', type: PoiType.comida,
        position: Offset(262, 270), nodeId: 'w0',
        price: 55, kcal: 720, rating: 4.2, dish: 'Comida corrida'),
    Poi(id: 'f2', name: 'Ciberterraza F', type: PoiType.comida,
        position: Offset(330, 601), nodeId: 'c6',
        price: 45, kcal: 480, rating: 4.0, dish: 'Sándwich y café'),
    Poi(id: 'f3', name: 'Ciberterraza E', type: PoiType.comida,
        position: Offset(357, 651), nodeId: 'p1',
        price: 38, kcal: 420, rating: 4.1, dish: 'Molletes y jugo'),
    Poi(id: 'f4', name: 'Cafetería Biblioteca CID', type: PoiType.comida,
        position: Offset(346, 692), nodeId: 's5',
        price: 60, kcal: 650, rating: 3.9, dish: 'Pasta del día'),
    // Emprendedores (alumnos vendedores)
    Poi(id: 'e1', name: 'Tacos Leones · Módulo S', type: PoiType.emprendedor,
        position: Offset(278, 424), nodeId: 'w2',
        price: 30, kcal: 520, rating: 4.6, dish: '3 tacos de guisado'),
    Poi(id: 'e2', name: 'Burritos Ing. Química', type: PoiType.emprendedor,
        position: Offset(312, 548), nodeId: 'c5',
        price: 25, kcal: 450, rating: 4.4, dish: 'Burrito de frijol'),
    Poi(id: 'e3', name: 'Fruta y yogur · Módulo N', type: PoiType.emprendedor,
        position: Offset(292, 494), nodeId: 'c4',
        price: 20, kcal: 180, rating: 4.7, dish: 'Fruta con yogur'),
    Poi(id: 'e4', name: 'Tortas · Módulo Q', type: PoiType.emprendedor,
        position: Offset(420, 396), nodeId: 'b2',
        price: 45, kcal: 780, rating: 4.3, dish: 'Torta ahogada'),
    Poi(id: 'e5', name: 'Ensaladas Fit CUCEI', type: PoiType.emprendedor,
        position: Offset(420, 458), nodeId: 'b3',
        price: 50, kcal: 350, rating: 4.5, dish: 'Ensalada con pollo'),
    Poi(id: 'e6', name: 'Comida casera Vocacional', type: PoiType.emprendedor,
        position: Offset(226, 566), nodeId: 'vc',
        price: 55, kcal: 850, rating: 4.0, dish: 'Guisado con arroz'),
    Poi(id: 'e7', name: 'Hot cakes · Módulo D', type: PoiType.emprendedor,
        position: Offset(372, 722), nodeId: 's5',
        price: 22, kcal: 380, rating: 4.2, dish: 'Hot cakes'),
    Poi(id: 'e8', name: 'Frutas del Coliseo', type: PoiType.emprendedor,
        position: Offset(506, 346), nodeId: 'k0',
        price: 25, kcal: 210, rating: 4.4, dish: 'Fruta picada'),
    Poi(id: 'e9', name: 'Tostadas Politécnico', type: PoiType.emprendedor,
        position: Offset(446, 262), nodeId: 'a1',
        price: 35, kcal: 500, rating: 4.1, dish: '2 tostadas'),
    // Hidratación (bebederos)
    Poi(id: 'w1', name: 'Bebedero Módulo O', type: PoiType.agua,
        position: Offset(240, 452), nodeId: 'w3'),
    Poi(id: 'w2', name: 'Bebedero Módulo S2', type: PoiType.agua,
        position: Offset(280, 384), nodeId: 'w2'),
    Poi(id: 'w3', name: 'Bebedero Módulo K', type: PoiType.agua,
        position: Offset(290, 556), nodeId: 'c6'),
    Poi(id: 'w4', name: 'Bebedero Biblioteca CID', type: PoiType.agua,
        position: Offset(318, 728), nodeId: 's5'),
    Poi(id: 'w5', name: 'Bebedero Módulo E', type: PoiType.agua,
        position: Offset(232, 632), nodeId: 's0'),
    Poi(id: 'w6', name: 'Bebedero Entrada Norte', type: PoiType.agua,
        position: Offset(452, 214), nodeId: 'gN'),
    Poi(id: 'w7', name: 'Bebedero Canchas', type: PoiType.agua,
        position: Offset(540, 414), nodeId: 'k1'),
    Poi(id: 'w8', name: 'Bebedero Estadio / Alberca', type: PoiType.agua,
        position: Offset(560, 612), nodeId: 'r2'),
    Poi(id: 'w9', name: 'Bebedero Politécnico', type: PoiType.agua,
        position: Offset(332, 306), nodeId: 'c2'),
    Poi(id: 'w10', name: 'Bebedero Prepa', type: PoiType.agua,
        position: Offset(142, 472), nodeId: 'pr'),
    // Servicios
    Poi(id: 's1', name: 'Biblioteca CID', type: PoiType.servicio,
        position: Offset(345, 697), nodeId: 's5'),
    Poi(id: 's2', name: 'Consultorios médicos', type: PoiType.servicio,
        position: Offset(262, 621), nodeId: 's0'),
    Poi(id: 's3', name: 'Auditorio Módulo O', type: PoiType.servicio,
        position: Offset(292, 435), nodeId: 'c4'),
    Poi(id: 's4', name: 'Coordinación de Fotónica', type: PoiType.servicio,
        position: Offset(256, 433), nodeId: 'w3'),
  ];

  static Iterable<Poi> get foodPois => pois.where((p) => p.isFood);
  static Iterable<Poi> get waterPois =>
      pois.where((p) => p.type == PoiType.agua);
}
