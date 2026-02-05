// Supabase Edge Function for AI-powered item categorization
// Deploy with: supabase functions deploy categorize-item

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const GROCERY_CATEGORIES = [
  "Produce",
  "Refrigerated",
  "Frozen",
  "Bakery",
  "Deli & Prepared",
  "Meat & Seafood",
  "International",
  "Canned & Jarred",
  "Dry Goods & Pasta",
  "Snacks & Candy",
  "Beverages",
  "Household",
  "Personal Care",
  "Pet Supplies",
  "Other",
];

const SHOPPING_CATEGORIES = [
  "Clothing",
  "Shoes",
  "Jewelry",
  "Electronics",
  "Toys & Games",
  "Home & Garden",
  "Sports & Outdoors",
  "Beauty",
  "Books & Media",
  "Accessories",
  "Gifts",
  "Other",
];

// Keep CATEGORIES as alias for backwards compatibility
const CATEGORIES = GROCERY_CATEGORIES;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CategorizeRequest {
  item_name: string;
  list_type?: "grocery" | "shopping" | "project";
}

interface CategorizeResponse {
  category: string;
  confidence: number;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Parse request body once and store it
  let item_name = "";
  let list_type: "grocery" | "shopping" | "project" = "grocery";
  try {
    const body: CategorizeRequest = await req.json();
    item_name = body.item_name || "";
    list_type = body.list_type || "grocery";
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Invalid request body" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  if (!item_name || item_name.trim().length === 0) {
    return new Response(
      JSON.stringify({ error: "item_name is required" }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // Project lists don't need categorization
  if (list_type === "project") {
    return new Response(
      JSON.stringify({ category: null, confidence: 0.0 }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }

  // Select categories based on list type
  const categories = list_type === "shopping" ? SHOPPING_CATEGORIES : GROCERY_CATEGORIES;

  try {
    if (!ANTHROPIC_API_KEY) {
      // Fallback to simple keyword matching if no API key
      const category = list_type === "shopping"
        ? fallbackCategorizeForShopping(item_name)
        : fallbackCategorize(item_name);
      return new Response(
        JSON.stringify({ category, confidence: 0.5 }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call Claude API for categorization
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-haiku-20240307",
        max_tokens: 100,
        messages: [
          {
            role: "user",
            content: `Categorize this ${list_type === "shopping" ? "shopping" : "grocery"} list item into exactly one of these categories: ${categories.join(", ")}.

Item: "${item_name}"

Respond with ONLY a JSON object in this exact format:
{"category": "CategoryName", "confidence": 0.95}

The confidence should be between 0 and 1.`,
          },
        ],
      }),
    });

    if (!response.ok) {
      throw new Error(`Claude API error: ${response.status}`);
    }

    const data = await response.json();
    const content = data.content[0].text;

    // Parse the JSON response
    const result: CategorizeResponse = JSON.parse(content);

    // Validate category is in our list
    if (!categories.includes(result.category)) {
      result.category = "Other";
      result.confidence = 0.5;
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error:", error);

    // Fallback to simple categorization on error
    // Use the already-parsed item_name variable
    const category = list_type === "shopping"
      ? fallbackCategorizeForShopping(item_name)
      : fallbackCategorize(item_name);

    return new Response(
      JSON.stringify({ category, confidence: 0.3 }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Simple keyword-based fallback categorization
function fallbackCategorize(itemName: string): string {
  const name = itemName.toLowerCase();

  const keywords: Record<string, string[]> = {
    Produce: [
      "apple",
      "banana",
      "orange",
      "lettuce",
      "tomato",
      "onion",
      "potato",
      "carrot",
      "broccoli",
      "spinach",
      "fruit",
      "vegetable",
      "pepper",
      "cucumber",
      "avocado",
    ],
    Refrigerated: ["milk", "cheese", "yogurt", "butter", "cream", "egg", "juice", "dairy"],
    Frozen: ["ice cream", "frozen", "pizza", "frozen meal", "frozen vegetable"],
    Bakery: ["bread", "bagel", "muffin", "croissant", "cake", "donut", "roll", "pastry"],
    "Deli & Prepared": ["deli", "prepared", "sandwich", "salad", "hummus", "dip"],
    "Meat & Seafood": [
      "chicken",
      "beef",
      "pork",
      "fish",
      "salmon",
      "shrimp",
      "turkey",
      "bacon",
      "sausage",
      "meat",
      "seafood",
    ],
    International: ["asian", "mexican", "italian", "sushi", "taco", "pasta sauce", "soy sauce"],
    "Canned & Jarred": [
      "can",
      "canned",
      "jar",
      "jarred",
      "soup",
      "sauce",
      "pickle",
      "olive",
    ],
    "Dry Goods & Pasta": [
      "rice",
      "pasta",
      "cereal",
      "flour",
      "sugar",
      "salt",
      "spice",
      "bean",
      "lentil",
      "quinoa",
    ],
    "Snacks & Candy": ["chip", "cookie", "candy", "chocolate", "cracker", "snack", "popcorn"],
    Beverages: ["drink", "soda", "water", "coffee", "tea", "juice", "beer", "wine"],
    Household: [
      "paper",
      "towel",
      "tissue",
      "cleaner",
      "detergent",
      "soap",
      "sponge",
      "trash bag",
      "battery",
      "light bulb",
    ],
    "Personal Care": [
      "shampoo",
      "toothpaste",
      "deodorant",
      "lotion",
      "razor",
      "soap",
      "toilet paper",
    ],
    "Pet Supplies": ["dog", "cat", "pet", "kibble", "litter", "treat", "toy"],
  };

  for (const [category, words] of Object.entries(keywords)) {
    if (words.some((word) => name.includes(word))) {
      return category;
    }
  }

  return "Other";
}

// Simple keyword-based fallback categorization for shopping lists
function fallbackCategorizeForShopping(itemName: string): string {
  const name = itemName.toLowerCase();

  const keywords: Record<string, string[]> = {
    Clothing: ["shirt", "pants", "dress", "jeans", "jacket", "sweater", "coat", "skirt", "shorts"],
    Shoes: ["shoes", "sneakers", "boots", "sandals", "heels", "flats", "loafers"],
    Jewelry: ["ring", "necklace", "bracelet", "earring", "watch", "jewelry", "pendant"],
    Electronics: ["phone", "laptop", "tablet", "headphones", "charger", "cable", "camera", "tv", "computer"],
    "Toys & Games": ["toy", "game", "lego", "puzzle", "doll", "action figure", "board game"],
    "Home & Garden": ["furniture", "lamp", "rug", "curtain", "pillow", "plant", "tool", "decor"],
    "Sports & Outdoors": ["ball", "racket", "weights", "bike", "camping", "tent", "hiking", "yoga"],
    Beauty: ["makeup", "lipstick", "perfume", "skincare", "mascara", "foundation", "nail polish"],
    "Books & Media": ["book", "magazine", "cd", "dvd", "vinyl", "album", "movie"],
    Accessories: ["bag", "purse", "wallet", "belt", "hat", "scarf", "sunglasses", "backpack"],
    Gifts: ["gift", "present", "card", "wrapping", "flowers", "bouquet"],
  };

  for (const [category, words] of Object.entries(keywords)) {
    if (words.some((word) => name.includes(word))) {
      return category;
    }
  }

  return "Other";
}
