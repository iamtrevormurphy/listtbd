# Listapp Setup Guide

## Prerequisites

1. **Flutter SDK** (3.2.0 or higher)
   ```bash
   # macOS with Homebrew
   brew install flutter

   # Or download from https://flutter.dev/docs/get-started/install
   ```

2. **Supabase Account** - Create a free project at [supabase.com](https://supabase.com)

3. **Claude API Key** (optional, for AI categorization) - Get one at [anthropic.com](https://console.anthropic.com/)

## Quick Start

### 1. Install Flutter Dependencies

```bash
cd Listapp
flutter pub get
```

### 2. Set Up Supabase

1. Create a new Supabase project at [app.supabase.com](https://app.supabase.com)

2. Go to SQL Editor and run the migration:
   - Copy contents of `supabase/migrations/001_initial_schema.sql`
   - Paste and run in the SQL Editor

3. Get your credentials:
   - Go to Settings → API
   - Copy the **Project URL** and **anon/public key**

4. Update `lib/core/config/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String url = 'https://YOUR_PROJECT.supabase.co';
     static const String anonKey = 'YOUR_ANON_KEY';
   }
   ```

### 3. Enable Authentication Providers

1. Go to Authentication → Providers in Supabase dashboard
2. Enable **Email** (enabled by default)
3. (Optional) Enable **Google** and **Apple** for social login

### 4. Deploy Edge Function (Optional - for AI categorization)

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Set Claude API key as secret
supabase secrets set ANTHROPIC_API_KEY=sk-ant-xxx

# Deploy the function
supabase functions deploy categorize-item
```

### 5. Run the App

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Chrome (web)
flutter run -d chrome
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Root widget with routing
├── core/
│   ├── config/            # App configuration
│   └── constants/         # Categories, colors
├── data/
│   ├── models/            # Data classes
│   └── repositories/      # Database access
├── presentation/
│   ├── screens/           # UI screens
│   ├── widgets/           # Reusable widgets
│   └── providers/         # Riverpod providers
└── services/              # External services (AI, etc.)
```

## Features Implemented (Phase 1)

- [x] User authentication (email/password, Google, Apple)
- [x] Create and manage shopping lists
- [x] Add items with quick-add bar
- [x] Swipe right to archive (complete) items
- [x] Swipe left to delete items
- [x] Items grouped by category
- [x] Manual category selection
- [x] Archive screen to view completed items
- [x] Undo archive with snackbar action
- [x] Real-time sync across devices
- [x] Inline editing (name, notes, quantity)
- [x] AI categorization Edge Function ready

## Next Steps (Phase 2+)

- [ ] Integrate AI categorization on item add
- [ ] Implement repurchase prediction algorithm
- [ ] Add push notifications for suggestions
- [ ] Analytics dashboard
- [ ] Offline support with Hive caching

## Troubleshooting

**"Invalid Supabase URL"** - Make sure you copied the full URL including `https://`

**"RLS policy violation"** - Ensure the database migration ran successfully

**"Edge function not found"** - Deploy the function with `supabase functions deploy categorize-item`
