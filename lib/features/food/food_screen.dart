import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample items for demonstration
    final List<String> carousel1Images = [
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=600&auto=format&fit=crop&q=80',
    ];

    final List<String> carousel2Images = [
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=600&auto=format&fit=crop&q=80',
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      endDrawer: const _FilterDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Navigation Area: Back button, Title & Filter button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    tooltip: 'Regresar',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Menú',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        tooltip: 'Filtros',
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1b. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. First Carousel
              _buildCarousel(
                context: context,
                title: 'De emprendedores',
                images: carousel1Images,
              ),

              // 3. Spacing: 12 logical pixels gap
              const SizedBox(height: 12.0),

              // 4. Second Carousel
              _buildCarousel(
                context: context,
                title: 'Menu de locales',
                images: carousel2Images,
              ),

              const SizedBox(height: 20),

              // 5. Bottom Button: "AI"
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    // AI assistant action placeholder
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCarousel({
    required BuildContext context,
    required String title,
    required List<String> images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showVendorModal(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    width: 280,
                    color: AppColors.backgroundCard,
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryOrange,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.backgroundCard,
                          child: const Center(
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showVendorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B), // Dark blueish gray matching the image
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Profile Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=150&auto=format&fit=crop&q=80',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Vendor Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'La Cocina de Ana -\nEmprendedora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'La Cocina de Ana emprendedora conocer una interacción de platos de dietas de ana.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Dishes Section
                const Text(
                  'Platos principales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // List of Dishes
                _buildDishItem(
                  image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=100&auto=format&fit=crop&q=80',
                  name: 'Bol Saludable Completo',
                  description: 'Arroz integral, tofu, verduras',
                  price: '\$12.50',
                ),
                const SizedBox(height: 12),
                _buildDishItem(
                  image: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100&auto=format&fit=crop&q=80',
                  name: 'Bol Saludable Rev',
                  description: 'Arroz integral, tofu, verduras',
                  price: '\$12.50',
                ),
                const SizedBox(height: 12),
                _buildDishItem(
                  image: 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=100&auto=format&fit=crop&q=80',
                  name: 'Bol Saludable Completo',
                  description: 'Arroz integral, tofu, verduras',
                  price: '\$12.50',
                ),
                const SizedBox(height: 12),
                _buildDishItem(
                  image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=100&auto=format&fit=crop&q=80',
                  name: 'Bol Saludable',
                  description: 'Arroz integral, tofu, verduras',
                  price: '\$12.50',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDishItem({
    required String image,
    required String name,
    required String description,
    required String price,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.network(
            image,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 50,
              height: 50,
              color: Colors.grey,
              child: const Icon(Icons.fastfood, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FilterDrawer extends StatefulWidget {
  const _FilterDrawer();

  @override
  State<_FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<_FilterDrawer> {
  RangeValues _priceRange = const RangeValues(20, 100);
  final TextEditingController _minController = TextEditingController(text: '20');
  final TextEditingController _maxController = TextEditingController(text: '100');

  final Map<String, bool> _recommendations = {
    'Mejor Calificado': false,
    'Más Popular': false,
    'Al Sugerido': false,
    'Cerca de Mí': false,
  };

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.spa, 'name': 'Sanos', 'selected': false},
    {'icon': Icons.local_pizza, 'name': 'Pizzas', 'selected': false},
    {'icon': Icons.cake, 'name': 'Postres', 'selected': false},
    {'icon': Icons.eco, 'name': 'Vegano', 'selected': false},
    {'icon': Icons.breakfast_dining, 'name': 'Tacos', 'selected': false},
    {'icon': Icons.lunch_dining, 'name': 'Burgers', 'selected': false},
    {'icon': Icons.grass, 'name': 'Ensaladas', 'selected': false},
    {'icon': Icons.ramen_dining, 'name': 'Oriental', 'selected': false},
    {'icon': Icons.local_drink, 'name': 'Bebidas', 'selected': false},
  ];

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros Detallados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Rango de Precio
                  _buildSectionTitle('Rango de Precio'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceInput(_minController, 'Mín'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPriceInput(_maxController, 'Máx'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryOrange,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.primaryOrange,
                      overlayColor: AppColors.primaryOrange.withValues(alpha: 0.2),
                      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                    ),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 20,
                      max: 500,
                      divisions: 100,
                      labels: RangeLabels(
                        '\$${_priceRange.start.round()}',
                        '\$${_priceRange.end.round()}',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _priceRange = values;
                          _minController.text = values.start.round().toString();
                          _maxController.text = values.end.round().toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Recomendación
                  _buildSectionTitle('Recomendación'),
                  const SizedBox(height: 8),
                  ..._recommendations.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key, style: const TextStyle(color: Colors.white70)),
                      value: _recommendations[key],
                      activeColor: AppColors.primaryOrange,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (bool? value) {
                        setState(() {
                          _recommendations[key] = value ?? false;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),

                  // Categorías de Comida
                  _buildSectionTitle('Categorías de Comida'),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category['selected'] as bool;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            category['selected'] = !isSelected;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.primaryOrange.withValues(alpha: 0.2)
                                : AppColors.backgroundCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.primaryOrange 
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category['icon'] as IconData,
                                color: isSelected ? AppColors.primaryOrange : Colors.white54,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category['name'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close drawer
                  },
                  child: const Text(
                    'Aplicar filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPriceInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixText: '\$ ',
        prefixStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (value) {
        final val = double.tryParse(value);
        if (val != null && val >= 20 && val <= 500) {
          setState(() {
            if (label == 'Mín' && val <= _priceRange.end) {
              _priceRange = RangeValues(val, _priceRange.end);
            } else if (label == 'Máx' && val >= _priceRange.start) {
              _priceRange = RangeValues(_priceRange.start, val);
            }
          });
        }
      },
    );
  }
}
