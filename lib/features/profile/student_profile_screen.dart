import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
    required this.studentName,
    super.key,
  });

  final String studentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryNavy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Regresar al dashboard',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBDB9BC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(48),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      const SizedBox(
                        width: 172,
                        height: 172,
                        child: CircleAvatar(
                          backgroundColor: Color(0xFFCBE2FF),
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF315B78),
                            size: 126,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
