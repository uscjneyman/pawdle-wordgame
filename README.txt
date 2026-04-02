Pawdle (WordGame) - Architecture and API Overview

Project Summary
Pawdle is an iOS SwiftUI riddle-driven word game. A player gets a riddle, then guesses a hidden word using Wordle-style feedback (correct/present/absent). The app includes local persistence, cloud sync via Supabase, category/difficulty filters, rewards, a community board, and audio feedback.

Architecture
The app follows a lightweight MVVM structure with clear separation of concerns.

1. App Layer
- PawdleApp.swift
- Creates shared state stores and injects them as EnvironmentObjects.
- Starts/stops looping background music based on scene phase (active/background).

2. View Layer (SwiftUI screens)
- HomeContainerView: Root swipeable container (swipe between home and collection).
- StartView: Setup screen (category, word length, difficulty), starts a game. Includes top nav bar with instructions and profile icons.
- GameView: Main gameplay UI (grid, keyboard, hints, reveal actions).
- EndView: Win/loss summary, Show Off, rewards.
- CollectionTabView: Tabbed view switching between Won Words and Community.
- WonWordsView: List of completed wins with swipe-to-delete.
- WonWordDetailView: Detail page for a saved win with Show Off button.
- CommunityView: Public feed of community posts, newest first.
- ShowOffMenuView: Share via message or publish to community.
- ShowOffCardView: Celebration card rendered as image for sharing.
- ProfileView: User profile with username, paw points, sync status, and logout.
- TopNavBar: Shared navigation bar (instructions, sync status, profile) used across screens.
- OnboardingOverlayView: On-screen tutorial overlay with arrows for new users.
- HowToPlayView: Onboarding/tutorial pages (6 pages including community features).
- AuthView: Log in / sign up screen.
- SplashView: Animated mascot intro on app launch.

3. ViewModel Layer
- GameViewModel.swift
- Owns game session state, guessing logic, keyboard coloring, animation triggers, hint/reveal rules, scoring, and end-game handling.
- Coordinates async API calls via service layer.
- Updates UI through @Published properties.
- Provides playAgain() (restart with same settings) and goHome() (return to start screen).
- AppViewModel.swift
- Owns app-level sync orchestration (auth/session changes, foreground refreshes, cloud sync scheduling).
- Keeps `PawdleApp` focused on composition and lifecycle only.

4. Model Layer
- GameModels.swift: LetterState, Guess, LetterResult, GameSession, GameStatus.
- GameEngine.swift: Pure game rules (guess evaluation + scoring), no UI/network dependencies.
- WordCategory.swift: Category enum and seed-word pools.
- WonWord.swift: Persisted completed game record.
- Sticker.swift: Reward model and rarity logic.
- CommunityPost.swift: Public community post record.

5. Service Layer
- RiddleService.swift: Main game-content source from custom API.
- DictionaryService.swift: Fetches definitions used as optional hints/details.
- WordService.swift: Datamuse-backed fallback word source and filtering.
- SoundManager.swift: Background music + built-in success/failure tones.
- SupabaseAuthService.swift / SupabasePlayerDataService.swift: Auth + cloud persistence APIs.
- CommunityService.swift: Fetches and publishes posts to the community_posts table.
- SyncErrorClassifier.swift: Network-vs-server error classification used by sync status.
- ServiceProtocols.swift: Protocol contracts (`RiddleProviding`, `DictionaryProviding`) for ViewModel injection/testability.

6. Store Layer (local persistence + state)
- WonWordsStore.swift: Save/load won game records to UserDefaults (JSON).
- PawPointsStore.swift: Save/load paw-point balance to UserDefaults.
- AuthStore.swift: Persists login session locally (token + expiry + user id + email), restores on app launch, supports logout.
- SyncStatusStore.swift: Tracks cloud sync state (idle/syncing/synced/failed).
- CommunityStore.swift: Manages community posts state and publish actions.

7. Auth + Cloud Sync Layer
- SupabaseAuthService.swift: Handles Supabase email/password sign in and sign up.
- SupabasePlayerDataService.swift: Syncs paw points and won words with Supabase when authenticated/online.


How the App Works (Runtime Flow)
1. App launches with SplashView, then fades to HomeContainerView.
2. HomeContainerView is a swipeable container: page 0 = StartView, page 1 = CollectionTabView.
3. New users see: tutorial (HowToPlayView) → auth (AuthView) → onboarding overlay (OnboardingOverlayView).
4. Player chooses category, difficulty, and word length on StartView.
5. GameViewModel.startNewGame() runs:
   - Calls RiddleService to fetch a random riddle matching filters.
   - Uses API answer as secret word.
   - Stores riddle text and starts a new GameSession.
6. In GameView:
   - Player types guesses on custom keyboard.
   - submitGuess() evaluates each letter using two-pass matching.
   - Grid and keyboard colors update based on results.
7. Optional helper actions:
   - Reveal a letter (costs paw points).
   - Reveal dictionary definition hint (costs paw points).
8. Game ends on win or max attempts:
   - EndView appears.
   - Rewards (paw points + sticker) applied for wins.
   - Show Off button lets user share or publish to community.
   - Play Again starts a new game with same settings.
   - Home returns to StartView.
9. Won words are persisted and listed in WonWordsView (swipe left from home).
10. Community board shows public posts from all players.
11. Navigation: top bar has ? (instructions), sync status, and profile icon on every screen.


External APIs Used
1. Custom Pawdle Riddle API (primary gameplay API)
- Base URL:
  https://pawdle-riddle-api-jneyman-8d9a88151bf0.herokuapp.com
- Purpose:
  Provides riddle + answer pairs filtered by category, difficulty, and answer length.

2. Free Dictionary API
- Endpoint pattern:
  https://api.dictionaryapi.dev/api/v2/entries/en/{word}
- Purpose:
  Retrieves definitions for optional hint text and detail screens.

3. Datamuse API (fallback content source)
- Endpoint pattern examples:
  https://api.datamuse.com/words?ml={seed}&sp={pattern}&md=fp&max=300
  https://api.datamuse.com/words?sp={pattern}&md=fp&max=1000
- Purpose:
  Fallback word selection if the custom riddle API cannot provide content.


Custom API Details (How It Was Integrated)
The custom API is integrated through RiddleService.swift.

Main Endpoints Consumed
1. Random riddle endpoint
- GET /api/riddles/random
- Query params used by app:
  - category: animals | mystery | science
  - difficulty: easy | medium | hard
  - length: integer (4-8 in app UI)

- Expected JSON shape:
  {
    "category": "animals",
    "length": 5,
    "difficulty": "easy",
    "riddle": "I purr and chase mice. What am I?",
    "answer": "cat"
  }

2. List endpoint (count check)
- GET /api/riddles
- Query params used:
  - category, difficulty, length
  - limit=1 (app only needs total count metadata)

- Expected JSON shape:
  {
    "total": 42
  }

Integration Rules in App
- The API answer is normalized to lowercase for consistent matching.
- Leading articles (a/an/the) are stripped.
- The answer must match selected word length.
- Previously solved words for same configuration are excluded server-side via the API `exclude` query parameter.
- If the current filtered pool is fully solved, the app shows a completion message.

Fallback Strategy
- If custom riddle fetch fails, app can still build playable words from Datamuse + local fallback pools.
- This keeps gameplay resilient even during API/network issues.


Persistence and Data Tracking
- Won words, metadata, and rewards are serialized as JSON in UserDefaults.
- Paw-point balance is stored in UserDefaults.
- This supports reopening the app without losing progress.
- App remains playable offline; cloud sync is best-effort and never blocks gameplay.
- On login, cloud profile/wins are merged into local state, then local state is pushed back to cloud.


Supabase Setup (Required Once)
To persist awards, won words, and community posts to Supabase, apply the migrations:

1. Migration files:
- supabase/migrations/20260323_player_data.sql (player profiles + won words)
- supabase/migrations/20260401_community_posts.sql (community board)

2. Apply migrations:
- supabase db push

3. What gets stored:
- player_profiles.paw_points
- won_words (word, tries, attempts, sticker, difficulty/category/length, won date)
- community_posts (username, word, tries, sticker, public feed)

4. Security model:
- Row Level Security is enabled on all tables.
- player_profiles and won_words: each user can only read/write their own rows.
- community_posts: anyone can read all posts, users can only insert/delete their own.


Concurrency and Networking
- Networking uses async/await with URLSession.
- UI state updates are coordinated on @MainActor via GameViewModel.
- Non-blocking tasks are used for fetches and delayed transitions.


Notes for Contributors
- Primary game content comes from RiddleService. Keep endpoint contracts stable.
- If API schema changes, update decodable response structs first.
- Keep normalization/filtering aligned with the custom API contract.
