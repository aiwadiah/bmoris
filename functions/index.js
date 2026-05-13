const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const DEFAULT_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash";

function normalizeHistory(history) {
  if (!Array.isArray(history)) return [];

  return history
    .map((item) => {
      if (!item || typeof item !== "object") return null;
      const role = item.role === "model" ? "model" : "user";

      if (Array.isArray(item.parts)) {
        const parts = item.parts
          .map((part) => {
            if (typeof part?.text === "string" && part.text.trim()) {
              return { text: part.text.trim() };
            }
            return null;
          })
          .filter(Boolean);
        return parts.length ? { role, parts } : null;
      }

      const text =
        typeof item.text === "string"
          ? item.text
          : typeof item.content === "string"
            ? item.content
            : null;

      if (!text || !text.trim()) return null;
      return { role, parts: [{ text: text.trim() }] };
    })
    .filter(Boolean);
}

async function getPrompt(field, fallback) {
  const doc = await db.collection("settings").doc("ai_prompts").get();
  if (doc.exists) {
    const value = doc.get(field);
    if (typeof value === "string" && value.trim()) {
      return value;
    }
  }
  return fallback;
}

async function callGemini({ apiKey, model = DEFAULT_MODEL, contents, generationConfig }) {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents, generationConfig }),
    },
  );

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new HttpsError(
      response.status === 429 ? "resource-exhausted" : "internal",
      data?.error?.message || "Gemini request failed.",
    );
  }

  const text = data?.candidates?.[0]?.content?.parts?.map((part) => part?.text || "").join("\n").trim();
  if (!text) {
    throw new HttpsError("internal", "Gemini returned an empty response.");
  }

  return { text, raw: data };
}

function parsePronunciationResponse({ userId, targetText, spokenText, aiResponse }) {
  let accuracyScore = 0;
  const scoreRegex = /(\d+)(?:\/100|%|\s*out of 100)/i;
  const match = aiResponse.match(scoreRegex);

  if (match) {
    accuracyScore = Math.max(0, Math.min(1, Number(match[1]) / 100));
  } else {
    const targetWords = targetText.toLowerCase().split(/\s+/).filter(Boolean);
    const spokenWords = spokenText.toLowerCase().split(/\s+/).filter(Boolean);
    let correctWords = 0;
    for (let i = 0; i < Math.min(targetWords.length, spokenWords.length); i += 1) {
      if (targetWords[i] === spokenWords[i]) correctWords += 1;
    }
    accuracyScore = targetWords.length ? correctWords / targetWords.length : 0;
  }

  const phonemeAnalysis = [];
  const malayPhonemes = ["ng", "ny", "kh", "sy", "gh"];
  const targetWords = targetText.toLowerCase().split(/\s+/).filter(Boolean);
  const spokenWords = spokenText.toLowerCase().split(/\s+/).filter(Boolean);

  for (let i = 0; i < targetWords.length; i += 1) {
    const targetWord = targetWords[i];
    const spokenWord = spokenWords[i] || "";

    for (const phoneme of malayPhonemes) {
      if (targetWord.includes(phoneme)) {
        const isCorrect = spokenWord.includes(phoneme);
        phonemeAnalysis.push({
          phoneme,
          isCorrect,
          score: isCorrect ? 1 : 0,
          suggestion: isCorrect
            ? `Good pronunciation of "${phoneme}"`
            : `Practice the "${phoneme}" sound${targetWord ? ` in "${targetWord}"` : ""}`,
        });
      }
    }
  }

  const resultLabel = accuracyScore >= 0.8 ? "Great" : accuracyScore >= 0.5 ? "Good" : "Bad";

  return {
    id: "",
    userId,
    targetText,
    spokenText,
    accuracyScore,
    phonemeAnalysis,
    feedback: aiResponse,
    attemptedAt: new Date().toISOString(),
    resultLabel,
  };
}

exports.chat = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const message = `${request.data?.message || ""}`.trim();
  if (!message) throw new HttpsError("invalid-argument", "message is required.");

  const promptTemplate = await getPrompt(
    "feedback",
    `You are BMoris, a helpful and friendly Bahasa Melayu language tutor.

User message: {user_message}

Respond to the user in a helpful and encouraging way. Always provide responses in both Malay and English to help them learn. Be patient and supportive.`,
  );

  const promptWithMessage = promptTemplate
    .replaceAll("{user_message}", message)
    .replaceAll("{performance_data}", "N/A");

  const contents = [
    ...normalizeHistory(request.data?.history),
    { role: "user", parts: [{ text: promptWithMessage }] },
  ];

  const { text } = await callGemini({
    apiKey: GEMINI_API_KEY.value(),
    contents,
    generationConfig: { temperature: 0.7, maxOutputTokens: 1024 },
  });

  return { reply: text };
});

exports.translate = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const text = `${request.data?.text || ""}`.trim();
  const fromLanguage = `${request.data?.fromLanguage || ""}`.trim();
  const toLanguage = `${request.data?.toLanguage || ""}`.trim();

  if (!text || !fromLanguage || !toLanguage) {
    throw new HttpsError("invalid-argument", "text, fromLanguage, and toLanguage are required.");
  }

  const prompt = `Translate from ${fromLanguage} to ${toLanguage}. Only provide the translation, no explanations: "${text}"`;

  const { text: translated } = await callGemini({
    apiKey: GEMINI_API_KEY.value(),
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.2, maxOutputTokens: 256 },
  });

  return { translation: translated };
});

exports.analyzePronunciation = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const userId = `${request.data?.userId || ""}`.trim();
  const targetText = `${request.data?.targetText || ""}`.trim();
  const spokenText = `${request.data?.spokenText || ""}`.trim();

  if (!targetText || !spokenText) {
    throw new HttpsError("invalid-argument", "targetText and spokenText are required.");
  }

  const promptTemplate = await getPrompt(
    "pronunciation",
    `You are a Bahasa Melayu pronunciation expert. Analyze the user's pronunciation and provide detailed feedback.

Target text: {target_text}
User's spoken text: {spoken_text}

Provide:
1. Overall accuracy score (0-100)
2. Phoneme-by-phoneme analysis
3. Specific suggestions for improvement
4. Encouraging feedback

Be constructive and helpful. Focus on the most important improvements first.`,
  );

  const prompt = promptTemplate
    .replaceAll("{target_text}", targetText)
    .replaceAll("{spoken_text}", spokenText);

  const { text: aiResponse } = await callGemini({
    apiKey: GEMINI_API_KEY.value(),
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.7, maxOutputTokens: 1024 },
  });

  return parsePronunciationResponse({ userId, targetText, spokenText, aiResponse });
});

exports.generateQuiz = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const topic = `${request.data?.topic || ""}`.trim();
  const category = `${request.data?.category || ""}`.trim();
  const difficulty = Number(request.data?.difficulty || 0);

  if (!topic || !category || Number.isNaN(difficulty)) {
    throw new HttpsError("invalid-argument", "topic, category, and difficulty are required.");
  }

  let prompt = await getPrompt(
    "quiz_generation",
    `You are a Bahasa Melayu language expert creating educational quiz questions.

Generate a multiple-choice quiz question for:
Topic: {topic}
Difficulty level: {difficulty}
Category: {category}

Requirements:
1. Question in both English and Bahasa Melayu
2. 4 answer options
3. One correct answer
4. Educational and engaging
5. Appropriate for the difficulty level

Return as JSON: {"question": "", "questionMalay": "", "options": [], "correctIndex": 0}`,
  );

  prompt = prompt
    .replaceAll("{topic}", topic)
    .replaceAll("{difficulty}", String(difficulty))
    .replaceAll("{category}", category);

  const { text: aiResponse } = await callGemini({
    apiKey: GEMINI_API_KEY.value(),
    contents: [{ parts: [{ text: prompt }] }],
    generationConfig: { temperature: 0.7, maxOutputTokens: 512 },
  });

  const cleaned = aiResponse.replace(/```json/gi, "").replace(/```/g, "").trim();
  let quizData;
  try {
    quizData = JSON.parse(cleaned);
  } catch (error) {
    throw new HttpsError("internal", "Quiz response was not valid JSON.");
  }

  if (!quizData?.question || !Array.isArray(quizData.options) || typeof quizData.correctIndex !== "number") {
    throw new HttpsError("internal", "Quiz response was missing required fields.");
  }

  return {
    question: quizData.question || "",
    questionMalay: quizData.questionMalay || quizData.question || "",
    options: quizData.options.map((option) => `${option}`),
    correctIndex: quizData.correctIndex || 0,
    difficulty,
    category,
    type: "multiple_choice",
    lessonId: "",
  };
});
