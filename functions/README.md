# BMoris Firebase Functions

This backend keeps the Gemini API key off the Flutter app.

## Production setup
1. Install Firebase CLI and log in.
2. Link the repo to the client's Firebase project.
3. Set the Gemini secret:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
4. Install dependencies and deploy:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

## Local emulator setup
1. Copy `.secret.local.example` to `.secret.local`.
2. Put a non-production Gemini key in `.secret.local`.
3. Run:
   ```bash
   cd functions
   npm install
   firebase emulators:start --only functions
   ```

## Callable functions
- `chat`
- `translate`
- `analyzePronunciation`
- `generateQuiz`
