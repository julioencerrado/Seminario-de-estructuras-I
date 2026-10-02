import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../food/food_scanner_screen.dart';
import '../food/food_screen.dart';
import '../map/campus_map_screen.dart';
import '../profile/student_profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCard,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Metas',
                    icon: Icons.emoji_flags,
                    child: _buildGoals(),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Registrar',
                    icon: Icons.add_task_rounded,
                    child: _buildRegisterSummary(context),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Anual',
                    icon: Icons.insights_rounded,
                    child: _buildAnnualSummary(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Regresar a Login',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, estudiante',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'Mi dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Abrir perfil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentProfileScreen(
                    studentName: 'Nombre del Alumno',
                  ),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryOrange,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: AppColors.progressYellow, size: 18),
              SizedBox(width: 8),
              Text(
                'Progreso diario',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text('Hoy', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 152,
            child: Row(
              children: [
                Expanded(
                  child: _buildProgressRing(
                    value: .92,
                    label: '92%',
                    caption: 'Actividad',
                    color: AppColors.progressTeal,
                    size: 128,
                  ),
                ),
                Expanded(
                  child: _buildProgressRing(
                    value: .60,
                    label: '60%',
                    caption: 'Nutrición',
                    color: AppColors.progressYellow,
                    size: 104,
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Image.asset(
                    'assets/images/mascota_progreso.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stackTrace) => const Icon(
                      Icons.emoji_emotions_rounded,
                      color: AppColors.primaryOrange,
                      size: 55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: .76,
              minHeight: 7,
              backgroundColor: Color(0x335A6B82),
              valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Vas muy bien. Completa una actividad más para alcanzar tu meta.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing({
    required double value,
    required String label,
    required String caption,
    required Color color,
    required double size,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: size > 115 ? 14 : 11,
                  color: color,
                  backgroundColor: Colors.white24,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size > 115 ? 22 : 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(caption, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textRed.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.textRed, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textRed,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz_rounded, color: Colors.black38),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildGoals() {
    return Row(
      children: [
        Expanded(
          child: _buildGoalsTile(
            icon: Icons.water_drop_sharp,
            title: 'Agua',
            detail: '0 L de X L consumidos',
            color: const Color.fromARGB(255, 18, 196, 240),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGoalsTile(
            icon: Icons.food_bank_sharp,
            title: 'Calorías',
            detail: '0 kcal de X kcal consumidas',
            color: const Color.fromARGB(255, 253, 136, 77),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsTile({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(height: 10),
          if (actionLabel == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Pendiente',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: color.withValues(alpha: .15),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  actionLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegisterSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildGoalsTile(
            icon: Icons.water_drop_rounded,
            title: 'Registrar agua',
            detail: 'Registra la cantidad de litros de agua consumidos.',
            color: const Color.fromARGB(255, 18, 196, 240),
            actionLabel: 'Registrar litros',
            onActionPressed: () => _showWaterRegistrationDialog(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildGoalsTile(
            icon: Icons.food_bank_rounded,
            title: 'Registrar calorías',
            detail: 'Registra la cantidad de calorías consumidas.',
            color: const Color.fromARGB(255, 253, 136, 77),
            actionLabel: 'Registrar calorías',
            onActionPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FoodScannerScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showWaterRegistrationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar agua'),
        content: TextField(
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Litros consumidos',
            hintText: 'Ej. 0.5',
            suffixText: 'L',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Actividad del año', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('2026', style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 105,
          width: double.infinity,
          child: CustomPaint(painter: _AnnualChartPainter()),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ene', style: TextStyle(color: Colors.black45, fontSize: 10)),
            Text('Mar', style: TextStyle(color: Colors.black45, fontSize: 10)),
            Text('Jun', style: TextStyle(color: Colors.black45, fontSize: 10)),
            Text('Sep', style: TextStyle(color: Colors.black45, fontSize: 10)),
            Text('Dic', style: TextStyle(color: Colors.black45, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      color: const Color(0xFF0C1929),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.kebab_dining, color: Colors.white70, size: 28),
                tooltip: 'Menú',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FoodScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white70, size: 30),
                tooltip: 'Inicio',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.white70, size: 28),
                tooltip: 'Mapa CUCEI',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CampusMapScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.water_drop_outlined, color: Colors.white70, size: 28),
                tooltip: 'Registrar agua',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnualChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * .70),
      Offset(size.width * .15, size.height * .52),
      Offset(size.width * .30, size.height * .78),
      Offset(size.width * .48, size.height * .28),
      Offset(size.width * .62, size.height * .10),
      Offset(size.width * .78, size.height * .54),
      Offset(size.width, size.height * .68),
    ];
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.textRed.withValues(alpha: .10),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.textRed
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(points[4], 4, Paint()..color = AppColors.textRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
