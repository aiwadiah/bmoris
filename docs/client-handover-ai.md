# Secure AI Handover Guide

This app no longer ships a live Gemini API key inside Flutter. All AI requests go through Firebase Cloud Functions.

## What the client must own
- Firebase project
- Gemini / Google AI billing account
- Production Gemini API key

## Production handover steps
1. Create or select the client's Firebase project.
2. Update Flutter Firebase config files if the client uses a different Firebase project.
3. Set the Gemini secret in Firebase:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
4. Deploy functions:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```
5. Build and test the Flutter app.
6. Rotate the key immediately if it was ever shared through chat or email.

## What not to do
- Do not paste the Gemini API key into any Dart file.
- Do not commit `.secret.local`, `.env`, or screenshots containing secrets.