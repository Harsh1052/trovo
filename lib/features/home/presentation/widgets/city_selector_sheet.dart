import 'package:flutter/material.dart';

import '../../../../config/theme/app_dimensions.dart';
import '../../../../config/theme/app_typography.dart';

class CitySelectorSheet extends StatelessWidget {
  const CitySelectorSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?> onCitySelected;

  static Future<String?> show(
    BuildContext context, {
    required List<String> cities,
    String? selectedCity,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySelectorSheet(
        cities: cities,
        selectedCity: selectedCity,
        onCitySelected: (city) => Navigator.of(context).pop(city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            child: Text('Select City', style: AppTypography.headlineSmall),
          ),
          ListTile(
            title: const Text('All Cities'),
            trailing: selectedCity == null
                ? const Icon(Icons.check_circle_rounded)
                : null,
            onTap: () => onCitySelected(null),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: cities.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final city = cities[i];
                return ListTile(
                  title: Text(city),
                  trailing: selectedCity == city
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  onTap: () => onCitySelected(city),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
