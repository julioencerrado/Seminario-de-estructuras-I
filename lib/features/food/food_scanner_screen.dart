import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FoodScannerScreen extends StatelessWidget {
  const FoodScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
        title: const Text('Registrar alimentos'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escanea tu alimento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coloca el alimento dentro del marco para identificarlo.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildCameraPreview(),
              const SizedBox(height: 14),
              const Text(
                'El escaneo con cámara estará disponible próximamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white30)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'O ingrésalo manualmente',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white30)),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showManualEntryDialog(context),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ingresar alimento manualmente'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return AspectRatio(
      aspectRatio: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF17283D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white54,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Vista de cámara',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: CustomPaint(
                  painter: _ScannerFramePainter(),
                ),
              ),
            ),
            const Positioned(
              bottom: 18,
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white54,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ingresar alimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nombre del alimento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calorías',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
}

class _ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const radius = 20.0;
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = AppColors.progressTeal
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    );
    canvas.drawRRect(frame, paint);

    final corners = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(cornerLength, 0)
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, cornerLength)
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(size.width - cornerLength, size.height)
      ..moveTo(cornerLength, size.height)
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, size.height - cornerLength);
    canvas.drawPath(corners, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) => false;
}
