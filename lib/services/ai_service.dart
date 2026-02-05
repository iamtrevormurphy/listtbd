import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/shopping_list.dart' show ListType;

/// Service for AI-powered features
class AIService {
  final SupabaseClient _client;

  AIService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Categorize an item using the Edge Function (with local fallback)
  /// Returns a map with 'category' and 'confidence'
  /// For project lists, returns null category (no categorization needed)
  Future<Map<String, dynamic>> categorizeItem(String itemName, {ListType listType = ListType.grocery}) async {
    // Project lists don't need categorization
    if (listType == ListType.project) {
      return {'category': null, 'confidence': 0.0};
    }

    try {
      final response = await _client.functions.invoke(
        'categorize-item',
        body: {
          'item_name': itemName,
          'list_type': listType.name,
        },
      );

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      // Fallback to local categorization
      return _localCategorize(itemName, listType: listType);
    } catch (e) {
      // Fallback to local categorization on error
      return _localCategorize(itemName, listType: listType);
    }
  }

  /// Local keyword-based categorization (fallback when Edge Function unavailable)
  /// Maps items to store aisles (grocery) or shopping categories (shopping)
  Map<String, dynamic> _localCategorize(String itemName, {ListType listType = ListType.grocery}) {
    final name = itemName.toLowerCase().trim();

    // For shopping lists, use shopping category keywords
    if (listType == ListType.shopping) {
      return _categorizeForShopping(name);
    }

    // Store aisle keywords - mapped to where items are found in stores
    const aisleKeywords = {
      'Produce': [
        'apple', 'banana', 'orange', 'lettuce', 'tomato', 'onion', 'potato',
        'carrot', 'broccoli', 'spinach', 'celery', 'cucumber', 'pepper',
        'garlic', 'lemon', 'lime', 'avocado', 'berry', 'strawberry',
        'blueberry', 'grape', 'melon', 'watermelon', 'mango', 'peach',
        'pear', 'plum', 'kiwi', 'pineapple', 'corn', 'mushroom', 'zucchini',
        'squash', 'cabbage', 'kale', 'arugula', 'herbs', 'basil', 'cilantro',
        'parsley', 'mint', 'ginger', 'asparagus', 'green bean', 'salad',
        'fruit', 'vegetable', 'fresh',
      ],
      'Refrigerated': [
        'milk', 'cheese', 'yogurt', 'butter', 'cream', 'egg', 'eggs',
        'cottage', 'sour cream', 'half and half', 'creamer', 'juice',
        'orange juice', 'almond milk', 'oat milk', 'tofu', 'hummus',
        'dip', 'refrigerated', 'cold brew', 'iced coffee', 'lemonade',
      ],
      'Frozen': [
        'frozen', 'ice cream', 'frozen pizza', 'popsicle', 'frozen waffle',
        'frozen fries', 'frozen vegetables', 'frozen fruit', 'frozen meal',
        'frozen dinner', 'sorbet', 'gelato', 'frozen burrito', 'frozen chicken',
        'ice', 'peas frozen', 'fish sticks',
      ],
      'Bakery': [
        'bread', 'bagel', 'muffin', 'croissant', 'cake', 'donut', 'roll',
        'bun', 'tortilla', 'pita', 'baguette', 'sourdough', 'cookie',
        'pie', 'pastry', 'cupcake', 'brownie', 'danish', 'scone',
      ],
      'Deli & Prepared': [
        'deli', 'sliced', 'turkey breast', 'ham', 'roast beef', 'salami',
        'prepared', 'rotisserie', 'chicken salad', 'potato salad',
        'coleslaw', 'sandwich', 'sub', 'wrap',
      ],
      'Meat & Seafood': [
        'chicken', 'beef', 'pork', 'fish', 'salmon', 'shrimp', 'turkey',
        'bacon', 'sausage', 'steak', 'ground beef', 'ground turkey',
        'lamb', 'tuna', 'crab', 'lobster', 'tilapia', 'cod', 'meatball',
        'hot dog', 'ribs', 'chop', 'roast', 'brisket', 'wings',
      ],
      'International': [
        'noodle', 'ramen', 'soy sauce', 'teriyaki', 'curry', 'coconut milk',
        'rice noodle', 'pad thai', 'salsa', 'tortilla chip', 'taco',
        'enchilada', 'refried beans', 'pasta sauce', 'olive oil', 'pesto',
        'asian', 'mexican', 'italian', 'indian', 'thai', 'chinese',
        'sriracha', 'hoisin', 'miso', 'wasabi', 'kimchi', 'gochujang',
      ],
      'Canned & Jarred': [
        'canned', 'can of', 'soup', 'beans', 'tomato sauce', 'diced tomato',
        'tomato paste', 'broth', 'stock', 'pickles', 'olives', 'jarred',
        'marinara', 'alfredo', 'jam', 'jelly', 'peanut butter', 'nutella',
        'canned tuna', 'canned chicken', 'corn can', 'green beans can',
      ],
      'Dry Goods & Pasta': [
        'pasta', 'spaghetti', 'penne', 'rice', 'quinoa', 'couscous',
        'cereal', 'oatmeal', 'oat', 'flour', 'sugar', 'baking',
        'pancake mix', 'bread crumbs', 'crackers', 'granola', 'muesli',
        'lentil', 'dried beans', 'mac and cheese', 'stuffing',
      ],
      'Snacks & Candy': [
        'chip', 'chips', 'popcorn', 'pretzel', 'nuts', 'almonds', 'cashews',
        'trail mix', 'candy', 'chocolate', 'gummy', 'cookie', 'snack bar',
        'granola bar', 'protein bar', 'jerky', 'dried fruit', 'goldfish',
      ],
      'Beverages': [
        'water', 'soda', 'coke', 'pepsi', 'sprite', 'coffee', 'tea',
        'beer', 'wine', 'energy drink', 'gatorade', 'sparkling water',
        'seltzer', 'kombucha', 'smoothie', 'drink mix', 'k-cup', 'pod',
      ],
      'Household': [
        'paper towel', 'toilet paper', 'tissue', 'napkin', 'cleaner',
        'detergent', 'soap', 'dish soap', 'sponge', 'trash bag', 'garbage bag',
        'foil', 'plastic wrap', 'ziploc', 'storage bag', 'plate', 'cup',
        'bowl', 'utensil', 'battery', 'light bulb', 'laundry', 'bleach',
        'wipe', 'wipes', 'dishwasher', 'dryer sheet', 'fabric softener',
      ],
      'Personal Care': [
        'shampoo', 'conditioner', 'toothpaste', 'toothbrush', 'deodorant',
        'lotion', 'razor', 'shave', 'body wash', 'face wash', 'sunscreen',
        'moisturizer', 'makeup', 'cosmetic', 'floss', 'mouthwash', 'cotton',
        'q-tip', 'bandaid', 'band-aid', 'medicine', 'vitamin', 'supplement',
        'ibuprofen', 'tylenol', 'allergy', 'cold medicine',
      ],
      'Pet Supplies': [
        'dog food', 'cat food', 'pet food', 'kibble', 'litter', 'cat litter',
        'dog treat', 'cat treat', 'pet treat', 'leash', 'collar', 'pet toy',
        'dog', 'cat', 'pet', 'puppy', 'kitten', 'bird seed', 'fish food',
      ],
    };

    // Check each aisle - longer phrases first for better matching
    for (final entry in aisleKeywords.entries) {
      // Sort keywords by length descending to match longer phrases first
      final sortedKeywords = List<String>.from(entry.value)
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final keyword in sortedKeywords) {
        if (name.contains(keyword)) {
          return {
            'category': entry.key,
            'confidence': 0.7,
          };
        }
      }
    }

    // Default to 'Other'
    return {
      'category': 'Other',
      'confidence': 0.3,
    };
  }

  /// Local keyword-based categorization for shopping lists
  Map<String, dynamic> _categorizeForShopping(String name) {
    const shoppingKeywords = {
      'Clothing': [
        'shirt', 'pants', 'jeans', 'dress', 'skirt', 'blouse', 'sweater',
        'jacket', 'coat', 'hoodie', 't-shirt', 'shorts', 'underwear', 'socks',
        'bra', 'pajamas', 'suit', 'tie', 'vest', 'cardigan', 'leggings',
      ],
      'Shoes': [
        'shoes', 'sneakers', 'boots', 'sandals', 'heels', 'flats', 'loafers',
        'slippers', 'flip flops', 'running shoes', 'dress shoes', 'athletic shoes',
      ],
      'Jewelry': [
        'ring', 'necklace', 'bracelet', 'earring', 'watch', 'jewelry',
        'pendant', 'chain', 'anklet', 'brooch', 'cufflinks',
      ],
      'Electronics': [
        'phone', 'laptop', 'computer', 'tablet', 'headphones', 'speaker',
        'charger', 'cable', 'battery', 'camera', 'tv', 'television', 'monitor',
        'keyboard', 'mouse', 'printer', 'router', 'usb', 'hdmi', 'airpods',
        'ipad', 'iphone', 'macbook', 'kindle', 'gaming', 'console', 'controller',
      ],
      'Toys & Games': [
        'toy', 'game', 'lego', 'puzzle', 'doll', 'action figure', 'board game',
        'video game', 'plush', 'stuffed animal', 'nerf', 'barbie', 'hot wheels',
        'playset', 'building blocks', 'rc car', 'drone',
      ],
      'Home & Garden': [
        'furniture', 'chair', 'table', 'lamp', 'rug', 'curtain', 'pillow',
        'blanket', 'vase', 'frame', 'mirror', 'plant', 'pot', 'garden',
        'tool', 'drill', 'hammer', 'screwdriver', 'paint', 'decor',
      ],
      'Sports & Outdoors': [
        'ball', 'bat', 'racket', 'golf', 'tennis', 'soccer', 'basketball',
        'football', 'yoga', 'weights', 'dumbbell', 'bike', 'bicycle',
        'camping', 'tent', 'sleeping bag', 'hiking', 'fishing', 'ski',
      ],
      'Beauty': [
        'makeup', 'lipstick', 'mascara', 'foundation', 'eyeshadow', 'blush',
        'perfume', 'cologne', 'skincare', 'serum', 'moisturizer', 'cleanser',
        'nail polish', 'hair dye', 'curling iron', 'straightener',
      ],
      'Books & Media': [
        'book', 'novel', 'magazine', 'comic', 'cd', 'dvd', 'vinyl', 'record',
        'album', 'movie', 'audiobook', 'ebook', 'textbook', 'journal', 'planner',
      ],
      'Accessories': [
        'bag', 'purse', 'wallet', 'belt', 'hat', 'cap', 'scarf', 'gloves',
        'sunglasses', 'umbrella', 'backpack', 'luggage', 'handbag', 'tote',
      ],
      'Gifts': [
        'gift', 'present', 'card', 'wrapping paper', 'ribbon', 'bow',
        'gift card', 'certificate', 'flowers', 'bouquet', 'chocolate box',
      ],
    };

    // Check each category - longer phrases first for better matching
    for (final entry in shoppingKeywords.entries) {
      final sortedKeywords = List<String>.from(entry.value)
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final keyword in sortedKeywords) {
        if (name.contains(keyword)) {
          return {
            'category': entry.key,
            'confidence': 0.7,
          };
        }
      }
    }

    // Default to 'Other'
    return {
      'category': 'Other',
      'confidence': 0.3,
    };
  }
}
