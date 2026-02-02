// Supabase Edge Function for AI-powered item categorization
// Deploy with: supabase functions deploy categorize-item

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

const CATEGORIES = [
  "Dairy",
  "Produce",
  "Meat & Seafood",
  "Bakery",
  "Pantry",
  "Frozen",
  "Household",
  "Personal Care",
  "Pet Supplies",
  "Other",
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CategorizeRequest {
  item_name: string;
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

  try {
    const { item_name }: CategorizeRequest = await req.json();

    if (!item_name || item_name.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "item_name is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!ANTHROPIC_API_KEY) {
      // Fallback to simple keyword matching if no API key
      const category = fallbackCategorize(item_name);
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
            content: `Categorize this shopping list item into exactly one of these categories: ${CATEGORIES.join(", ")}.

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
    if (!CATEGORIES.includes(result.category)) {
      result.category = "Other";
      result.confidence = 0.5;
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error:", error);

    // Fallback to simple categorization on error
    const { item_name } = await req.json().catch(() => ({ item_name: "" }));
    const category = fallbackCategorize(item_name);

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
    Dairy: ["milk", "cheese", "yogurt", "butter", "cream", "egg"],
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
    ],
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
    ],
    Bakery: ["bread", "bagel", "muffin", "croissant", "cake", "donut", "roll"],
    Pantry: [
      "rice",
      "pasta",
      "cereal",
      "soup",
      "sauce",
      "oil",
      "flour",
      "sugar",
      "salt",
      "spice",
      "can",
    ],
    Frozen: ["ice cream", "frozen", "pizza"],
    Household: [
      "paper",
      "towel",
      "tissue",
      "cleaner",
      "detergent",
      "soap",
      "sponge",
      "trash bag",
    ],
    "Personal Care": [
      "shampoo",
      "toothpaste",
      "deodorant",
      "lotion",
      "razor",
    ],
    "Pet Supplies": ["dog", "cat", "pet", "kibble", "litter"],
  };

  for (const [category, words] of Object.entries(keywords)) {
    if (words.some((word) => name.includes(word))) {
      return category;
    }
  }

  return "Other";
}
