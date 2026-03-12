Pawdle (WordGame) - Architecture and API Overview

Project Summary
Pawdle is an iOS SwiftUI riddle-driven word game. A player gets a riddle, then guesses a hidden word using Wordle-style feedback (correct/present/absent). The app includes local persistence, category/difficulty filters, rewards, and audio feedback.

Architecture
The app follows a lightweight MVVM structure with clear separation of concerns.

1. App Layer
- PawdleApp.swift
- Creates shared state stores and injects them as EnvironmentObjects.
- Starts/stops looping background music based on scene phase (active/background).

2. View Layer (SwiftUI screens)
- StartView: Setup screen (category, word length, difficulty), starts a game.
- GameView: Main gameplay UI (grid, keyboard, hints, reveal actions).
- EndView: Win/loss summary, share, rewards.
- WonWordsView: List of completed wins with swipe-to-delete.
- WonWordDetailView: Detail page for a saved win.
- HowToPlayView: Onboarding/tutorial pages.

3. ViewModel Layer
- GameViewModel.swift
- Owns game session state, guessing logic, keyboard coloring, animation triggers, hint/reveal rules, scoring, and end-game handling.
- Coordinates async API calls via service layer.
- Updates UI through @Published properties.

4. Model Layer
- GameModels.swift: LetterState, Guess, LetterResult, GameSession, GameStatus.
- WordCategory.swift: Category enum and seed-word pools.
- WonWord.swift: Persisted completed game record.
- Sticker.swift: Reward model and rarity logic.

5. Service Layer
- RiddleService.swift: Main game-content source from custom API.
- DictionaryService.swift: Fetches definitions used as optional hints/details.
- WordService.swift: Datamuse-backed fallback word source and filtering.
- SoundManager.swift: Background music + built-in success/failure tones.

6. Store Layer (local persistence)
- WonWordsStore.swift: Save/load won game records to UserDefaults (JSON).
- PawPointsStore.swift: Save/load paw-point balance to UserDefaults.


How the App Works (Runtime Flow)
1. App launches to StartView.
2. Player chooses category, difficulty, and word length.
3. GameViewModel.startNewGame() runs:
   - Calls RiddleService to fetch a random riddle matching filters.
   - Uses API answer as secret word.
   - Stores riddle text and starts a new GameSession.
4. In GameView:
   - Player types guesses on custom keyboard.
   - submitGuess() evaluates each letter using two-pass matching.
   - Grid and keyboard colors update based on results.
5. Optional helper actions:
   - Reveal a letter (costs paw points).
   - Reveal dictionary definition hint (costs paw points).
6. Game ends on win or max attempts:
   - EndView appears.
   - Rewards (paw points + sticker) applied for wins.
   - Sound effect tone plays for win/loss.
7. Won words are persisted and listed in WonWordsView.


External APIs Used
1. Custom Pawdle Riddle API (primary gameplay API)
- Custom API made on this app, stored on a heroku server. The riddles are basic, but will be updated to be better later, There are over 700 riddles. 
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
- The API answer is normalized to a single lowercase word.
- Leading articles (a/an/the) are stripped.
- Non-single-word answers are rejected.
- The answer must match selected word length.
- Previously solved words for same configuration are excluded.
- Up to 20 attempts are made to find a valid riddle/answer pair.

Fallback Strategy
- If custom riddle fetch fails, app can still build playable words from Datamuse + local fallback pools.
- This keeps gameplay resilient even during API/network issues.


Persistence and Data Tracking
- Won words, metadata, and rewards are serialized as JSON in UserDefaults.
- Paw-point balance is stored in UserDefaults.
- This supports reopening the app without losing progress.


Concurrency and Networking
- Networking uses async/await with URLSession.
- UI state updates are coordinated on @MainActor via GameViewModel.
- Non-blocking tasks are used for fetches and delayed transitions.


Notes for Contributors
- Primary game content comes from RiddleService. Keep endpoint contracts stable.
- If API schema changes, update decodable response structs first.
- Keep model filtering strict so only playable single-word answers are accepted.
