# Listapp - AI-Powered Smart Shopping List App

## 1. Services Needed

### Authentication
- **Supabase Auth** - Email/password, social logins (Google, Apple), magic links
- Built-in Row Level Security (RLS) for data protection
- Session management and JWT tokens

### Database
- **Supabase (PostgreSQL)** - Relational database with:
  - Real-time subscriptions for live updates
  - Full-text search capabilities
  - Vector storage for AI embeddings (pgvector)
  - No vendor lock-in (standard PostgreSQL)

### AI Services
- **Claude API (Anthropic)** or **OpenAI API** for:
  - Auto-categorization of list items
  - Natural language understanding
  - Pattern recognition in purchase history
- **Custom ML model** (optional, phase 2) for:
  - Repurchase prediction using RFM analysis
  - Purchase frequency modeling

### Storage
- **Supabase Storage** - For user profile images, receipts, etc.

### Push Notifications
- **Firebase Cloud Messaging (FCM)** - Cross-platform push notifications for repurchase reminders

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT (Flutter)                         │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │  List UI  │  │  Swipe    │  │  Item     │  │  AI       │   │
│  │  (Home)   │  │  Actions  │  │  Editor   │  │  Suggest  │   │
│  └───────────┘  └───────────┘  └───────────┘  └───────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE BACKEND                           │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │   Auth    │  │  Realtime │  │  Database │  │  Storage  │   │
│  │  Service  │  │  Engine   │  │  (Postgres)│  │           │   │
│  └───────────┘  └───────────┘  └───────────┘  └───────────┘   │
│                              │                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │              Edge Functions (Deno)                         │ │
│  │  • AI Categorization  • Repurchase Prediction             │ │
│  │  • Notification Scheduler                                  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                          │
│  ┌───────────────────┐  ┌───────────────────────────────────┐  │
│  │  Claude/OpenAI    │  │  Firebase Cloud Messaging         │  │
│  │  API              │  │  (Push Notifications)             │  │
│  └───────────────────┘  └───────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Add Item**: User types item → Edge Function calls AI for categorization → Item saved with category
2. **Swipe to Clear**: Item marked as archived → Purchase history updated → Triggers repurchase analysis
3. **Repurchase Suggestions**: Scheduled job analyzes history → Calculates intervals → Sends push notifications

---

## 3. Security Considerations

### Authentication & Authorization
- [ ] Implement Row Level Security (RLS) policies on all tables
- [ ] Use Supabase Auth with secure session handling
- [ ] Enforce HTTPS for all API communications
- [ ] Implement rate limiting on Edge Functions

### Data Protection
- [ ] Encrypt sensitive data at rest (Supabase default)
- [ ] Never store API keys in client code - use Edge Functions
- [ ] Implement proper input sanitization before AI processing
- [ ] Use parameterized queries (Supabase client handles this)

### API Security
- [ ] Store Claude/OpenAI API keys in Supabase Vault (encrypted secrets)
- [ ] Implement request validation in Edge Functions
- [ ] Set up CORS policies for web clients
- [ ] Use short-lived JWT tokens with refresh rotation

### Privacy
- [ ] Anonymize data sent to AI services (strip user identifiers)
- [ ] Implement data retention policies for archived items
- [ ] Provide data export and deletion capabilities (GDPR compliance)
- [ ] Clear privacy policy explaining AI usage

---

## 4. Recommended Tech Stack

### Frontend
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Framework | **Flutter 3.x** | Superior gesture handling, 120Hz animations, single codebase for iOS/Android |
| State Management | **Riverpod** | Type-safe, testable, good for async operations |
| Local Storage | **Hive** or **Isar** | Fast local caching for offline support |
| Gestures | **flutter_slidable** | Battle-tested swipe actions library |

### Backend
| Component | Technology | Rationale |
|-----------|------------|-----------|
| BaaS | **Supabase** | PostgreSQL flexibility, RLS, real-time, open source |
| Serverless | **Supabase Edge Functions** | Deno runtime, close to database, low latency |
| Database | **PostgreSQL + pgvector** | Relational + vector embeddings for AI |

### AI/ML
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Categorization | **Claude API (claude-3-haiku)** | Fast, cost-effective, excellent at classification |
| Embeddings | **OpenAI text-embedding-3-small** | For similarity search and pattern matching |
| Predictions | **Custom algorithm** | RFM-based frequency analysis (start simple) |

### Infrastructure
| Component | Technology | Rationale |
|-----------|------------|-----------|
| Hosting | **Supabase Cloud** | Managed, scalable, generous free tier |
| Push Notifications | **Firebase Cloud Messaging** | Industry standard, cross-platform |
| Analytics | **PostHog** or **Mixpanel** | Product analytics, self-hostable option |

---

## 5. File Structure

```
listapp/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── supabase_config.dart
│   │   │   └── theme_config.dart
│   │   ├── constants/
│   │   │   ├── categories.dart
│   │   │   └── app_constants.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── validators.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── list_item.dart
│   │   │   ├── category.dart
│   │   │   ├── purchase_history.dart
│   │   │   ├── repurchase_suggestion.dart
│   │   │   └── user.dart
│   │   ├── repositories/
│   │   │   ├── list_repository.dart
│   │   │   ├── archive_repository.dart
│   │   │   ├── suggestion_repository.dart
│   │   │   └── auth_repository.dart
│   │   └── datasources/
│   │       ├── supabase_datasource.dart
│   │       └── local_datasource.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   └── ... (if using clean architecture)
│   │   └── usecases/
│   │       ├── add_item.dart
│   │       ├── archive_item.dart
│   │       ├── get_suggestions.dart
│   │       └── categorize_item.dart
│   │
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── home_controller.dart
│   │   │   ├── list/
│   │   │   │   ├── list_screen.dart
│   │   │   │   └── list_controller.dart
│   │   │   ├── archive/
│   │   │   │   └── archive_screen.dart
│   │   │   ├── suggestions/
│   │   │   │   └── suggestions_screen.dart
│   │   │   └── auth/
│   │   │       ├── login_screen.dart
│   │   │       └── signup_screen.dart
│   │   ├── widgets/
│   │   │   ├── list_item_tile.dart
│   │   │   ├── swipeable_item.dart
│   │   │   ├── category_chip.dart
│   │   │   ├── quick_add_bar.dart
│   │   │   └── suggestion_card.dart
│   │   └── providers/
│   │       ├── list_provider.dart
│   │       ├── auth_provider.dart
│   │       └── suggestions_provider.dart
│   │
│   └── services/
│       ├── ai_service.dart
│       ├── notification_service.dart
│       └── analytics_service.dart
│
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_add_categories.sql
│   │   └── 003_add_purchase_history.sql
│   ├── functions/
│   │   ├── categorize-item/
│   │   │   └── index.ts
│   │   ├── calculate-repurchase/
│   │   │   └── index.ts
│   │   └── send-suggestions/
│   │       └── index.ts
│   └── seed.sql
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
└── README.md
```

---

## 6. Design Considerations

### User Experience

#### One-Click Add
- Persistent input bar at bottom of screen (like iOS Messages)
- Auto-focus on tap, submit on Enter/Done
- Optimistic UI: item appears immediately, category loads async
- Show loading shimmer on category chip while AI processes

#### Inline Editing
- Tap item text to edit inline (no modal)
- Tap category chip to manually override
- Long-press for additional options (notes, quantity, priority)

#### Swipe Gestures
- **Swipe right**: Archive item (green checkmark animation)
- **Swipe left**: Delete permanently (red trash animation)
- Haptic feedback on threshold reached
- Undo snackbar for 5 seconds after archive/delete

#### AI Suggestions
- Non-intrusive suggestion cards at top of list
- "Time to restock?" with item name and last purchase date
- One-tap to add to current list
- Dismiss to snooze for 1 week

### Visual Design

```
┌────────────────────────────────────┐
│  ☰  My Shopping List      ⚙️  👤  │
├────────────────────────────────────┤
│ ┌────────────────────────────────┐ │
│ │ 💡 Time to buy milk?           │ │
│ │    Last purchased 6 days ago   │ │
│ │              [Add] [Dismiss]   │ │
│ └────────────────────────────────┘ │
├────────────────────────────────────┤
│                                    │
│  🥛 Dairy                          │
│  ├─ ☐ Milk                         │
│  └─ ☐ Cheese                       │
│                                    │
│  🥬 Produce                        │
│  ├─ ☐ Bananas                      │
│  └─ ☐ Spinach                      │
│                                    │
│  🧹 Household                      │
│  └─ ☐ Paper towels                 │
│                                    │
├────────────────────────────────────┤
│  [________________________] [+]    │
│        Add an item...              │
└────────────────────────────────────┘
```

### Category System
Pre-defined categories with AI flexibility:
- 🥛 Dairy
- 🥬 Produce
- 🥩 Meat & Seafood
- 🍞 Bakery
- 🥫 Pantry
- ❄️ Frozen
- 🧹 Household
- 🧴 Personal Care
- 🐕 Pet Supplies
- 📦 Other

---

## 7. Step-by-Step Implementation Plan

### Phase 1: Foundation (MVP)
**Goal**: Basic list functionality with swipe actions

1. **Project Setup**
   - Initialize Flutter project
   - Set up Supabase project and local dev environment
   - Configure authentication (email + Google)
   - Create database schema (users, lists, items)

2. **Core List Features**
   - Build list screen with grouped items
   - Implement quick-add input bar
   - Add swipe-to-archive with flutter_slidable
   - Create archive screen to view cleared items

3. **Data Layer**
   - Set up Supabase client and Riverpod providers
   - Implement real-time subscriptions for list updates
   - Add offline support with local caching

### Phase 2: AI Categorization
**Goal**: Auto-categorize items when added

4. **Edge Function Setup**
   - Create `categorize-item` Edge Function
   - Integrate Claude API (claude-3-haiku for speed/cost)
   - Store API keys in Supabase Vault

5. **Categorization Flow**
   - On item add: call Edge Function
   - Return category + confidence score
   - Store category with item
   - Allow manual override via UI

6. **Category UI**
   - Display items grouped by category
   - Show category chips on items
   - Add category picker for manual selection

### Phase 3: Purchase History & Analytics
**Goal**: Track purchase patterns

7. **History Tracking**
   - On archive: create purchase_history record
   - Store: item_name, category, archived_at, user_id
   - Build archive browser with filters

8. **Analytics Dashboard** (optional)
   - Purchase frequency by category
   - Most purchased items
   - Spending patterns (if price tracking added)

### Phase 4: Repurchase Predictions
**Goal**: Smart suggestions based on history

9. **Prediction Algorithm**
   - Calculate average interval between purchases per item
   - Identify items approaching repurchase window
   - Start simple: `avg_interval * 0.9 = suggest_date`

10. **Edge Function: Predictions**
    - Create `calculate-repurchase` function
    - Run daily via Supabase cron (pg_cron)
    - Store suggestions in `repurchase_suggestions` table

11. **Suggestion UI**
    - Display suggestion cards on home screen
    - One-tap add to current list
    - Dismiss/snooze functionality

### Phase 5: Notifications & Polish
**Goal**: Proactive reminders

12. **Push Notifications**
    - Integrate Firebase Cloud Messaging
    - Send daily digest of suggestions (user-configurable)
    - Deep link to suggestion in app

13. **Polish & Optimization**
    - Performance optimization
    - Accessibility improvements
    - Error handling and edge cases
    - App store assets and submission

---

## Database Schema

```sql
-- Users (managed by Supabase Auth, extended with profile)
create table profiles (
  id uuid references auth.users primary key,
  display_name text,
  notification_preferences jsonb default '{"daily_digest": true}',
  created_at timestamptz default now()
);

-- Shopping Lists
create table lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  name text not null default 'Shopping List',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- List Items
create table items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid references lists(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  name text not null,
  category text,
  category_confidence float,
  notes text,
  quantity int default 1,
  is_archived boolean default false,
  archived_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Purchase History (for predictions)
create table purchase_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  item_name text not null,
  item_name_normalized text not null, -- lowercase, trimmed for matching
  category text,
  purchased_at timestamptz default now()
);

-- Repurchase Suggestions
create table repurchase_suggestions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  item_name text not null,
  category text,
  avg_interval_days int,
  last_purchased_at timestamptz,
  suggested_at timestamptz default now(),
  status text default 'pending', -- pending, added, dismissed
  dismissed_until timestamptz
);

-- Row Level Security
alter table profiles enable row level security;
alter table lists enable row level security;
alter table items enable row level security;
alter table purchase_history enable row level security;
alter table repurchase_suggestions enable row level security;

-- Policies (users can only access their own data)
create policy "Users can view own profile" on profiles
  for select using (auth.uid() = id);

create policy "Users can view own lists" on lists
  for all using (auth.uid() = user_id);

create policy "Users can manage own items" on items
  for all using (auth.uid() = user_id);

create policy "Users can view own history" on purchase_history
  for all using (auth.uid() = user_id);

create policy "Users can manage own suggestions" on repurchase_suggestions
  for all using (auth.uid() = user_id);
```

---

## Cost Estimates (Monthly)

| Service | Free Tier | Expected Cost (1k users) |
|---------|-----------|-------------------------|
| Supabase | 500MB DB, 2GB storage | $25/mo (Pro) |
| Claude API (Haiku) | - | ~$10-20/mo |
| Firebase (FCM) | Unlimited | Free |
| **Total** | - | **~$35-45/mo** |

---

## Research Sources

- [Codica - Tech Stack for Mobile Apps 2025](https://www.codica.com/blog/tech-stack-for-mobile-app/)
- [Flutter vs React Native 2026 Guide](https://www.luciq.ai/blog/flutter-vs-react-native-guide)
- [Supabase vs Firebase Comparison](https://supabase.com/alternatives/supabase-vs-firebase)
- [AI Categorization Best Practices](https://www.vellum.ai/blog/best-at-text-classification-gemini-pro-gpt-4-or-claude2)
- [Predictive Repurchase Analytics](https://www.sciencedirect.com/science/article/abs/pii/S0377221721003350)
- [Category Wizard - AI Grocery Analysis](https://www.categorywizard.com/grocery-lists.html)
