import 'package:flutter/material.dart';

class CategoryIcons {
  static const List<IconData> icons = [
    Icons.shopping_cart,
    Icons.fastfood,
    Icons.local_grocery_store,
    Icons.directions_car,
    Icons.local_taxi,
    Icons.flight,
    Icons.hotel,
    Icons.home,
    Icons.lightbulb,
    Icons.water_drop,
    Icons.phone_android,
    Icons.wifi,
    Icons.tv,
    Icons.movie,
    Icons.music_note,
    Icons.headphones,
    Icons.school,
    Icons.book,
    Icons.work,
    Icons.business,
    Icons.attach_money,
    Icons.credit_card,
    Icons.account_balance,
    Icons.health_and_safety,
    Icons.medical_services,
    Icons.fitness_center,
    Icons.spa,
    Icons.pets,
    Icons.child_care,
    Icons.toys,
    Icons.card_giftcard,
    Icons.cake,
    Icons.celebration,
    Icons.restaurant,
    Icons.coffee,
    Icons.local_bar,
    Icons.shopping_bag,
    Icons.checkroom,
    Icons.watch,
    Icons.laptop,
    Icons.devices,
    Icons.build,
    Icons.handyman,
    Icons.security,
    Icons.travel_explore,
    Icons.map,
    Icons.event,
  ];

  // =====================================================
  // 🎨 PERMANENT COLOR RESOLUTION (NO MISSING COLORS)
  // =====================================================
  static Color colorForIcon(IconData icon) {
    // Stable palette (finance-safe & soft)
    const palette = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
      Colors.purple,
      Colors.cyan,
      Colors.brown,
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.redAccent,
    ];

    // 🔥 KEY FIX:
    // Use icon.codePoint to always derive a color
    final index = icon.codePoint % palette.length;
    return palette[index];
  }
}
