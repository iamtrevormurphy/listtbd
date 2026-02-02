/// Store aisle categories - where you'd find items in a typical grocery store
class StoreAisles {
  static const List<Aisle> all = [
    Aisle(name: 'Produce', icon: '🥬', description: 'Fresh fruits & vegetables'),
    Aisle(name: 'Refrigerated', icon: '🥛', description: 'Dairy, eggs, yogurt, juice'),
    Aisle(name: 'Frozen', icon: '🧊', description: 'Frozen meals, ice cream, vegetables'),
    Aisle(name: 'Bakery', icon: '🍞', description: 'Bread, pastries, cakes'),
    Aisle(name: 'Deli & Prepared', icon: '🥪', description: 'Deli meats, prepared foods'),
    Aisle(name: 'Meat & Seafood', icon: '🥩', description: 'Fresh meat, poultry, fish'),
    Aisle(name: 'International', icon: '🌍', description: 'Asian, Mexican, Italian foods'),
    Aisle(name: 'Canned & Jarred', icon: '🥫', description: 'Canned goods, sauces, soups'),
    Aisle(name: 'Dry Goods & Pasta', icon: '🍝', description: 'Pasta, rice, cereals, flour'),
    Aisle(name: 'Snacks & Candy', icon: '🍿', description: 'Chips, cookies, chocolate'),
    Aisle(name: 'Beverages', icon: '🥤', description: 'Drinks, coffee, tea, water'),
    Aisle(name: 'Household', icon: '🧹', description: 'Cleaning, paper goods, storage'),
    Aisle(name: 'Personal Care', icon: '🧴', description: 'Health, beauty, hygiene'),
    Aisle(name: 'Pet Supplies', icon: '🐕', description: 'Pet food, treats, accessories'),
    Aisle(name: 'Other', icon: '📦', description: 'Miscellaneous items'),
  ];

  static Aisle getByName(String name) {
    return all.firstWhere(
      (a) => a.name.toLowerCase() == name.toLowerCase(),
      orElse: () => all.last, // Default to 'Other'
    );
  }

  static String getIcon(String aisleName) {
    return getByName(aisleName).icon;
  }

  /// Alias for getIcon for backwards compatibility.
  static String getEmoji(String aisleName) => getIcon(aisleName);

  static List<String> get names => all.map((a) => a.name).toList();

  // Prevent instantiation
  StoreAisles._();
}

class Aisle {
  final String name;
  final String icon;
  final String description;

  const Aisle({
    required this.name,
    required this.icon,
    required this.description,
  });
}

// Keep Categories as alias for backwards compatibility
typedef Categories = StoreAisles;
