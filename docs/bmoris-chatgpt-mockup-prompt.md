# BMoris ChatGPT Mockup Prompt

Use the prompt below in ChatGPT to generate a full mockup direction for the BMoris app redesign.

## Master Prompt

```text
Act as a senior mobile product designer and visual design director. Create a high-fidelity mobile app mockup system for an educational app called BMoris, a Bahasa Melayu learning app focused on pronunciation, speaking confidence, vocabulary, quizzes, and AI-assisted conversation.

Design goal:
Redesign BMoris so it feels inspired by Duolingo's clarity, warmth, rounded playfulness, and motivational energy, but more premium, more polished, and slightly more mature. It must not feel like a clone. It should feel like a modern Malay language learning app with its own identity.

Core creative direction:
- Visual style: Playful Premium
- Platform: mobile app mockups only
- Brand feel: cheerful, intelligent, polished, motivating, culturally grounded
- Inspiration: Duolingo-style engagement loops, bold hierarchy, clear progress, friendly illustrations
- BMoris twist: a stronger premium finish, calmer surfaces, tighter spacing discipline, better typography, more elegant cards, and more intentional visual rhythm

Brand and identity requirements:
- Keep BMoris as the app name
- Preserve the Dodo mascot as a recurring brand companion
- Preserve subtle Bahasa Melayu learning cues in the interface, microcopy, badges, illustrations, and visual storytelling
- UI copy should mostly be in Bahasa Melayu, with English only where it feels natural for product terms
- Avoid generic AI-slop education UI
- Avoid direct duplication of Duolingo screens, layouts, or mascot behavior

Design system rules:
- Rounded cards, rounded buttons, soft but crisp shadows
- Strong visual hierarchy with bold section titles and compact supporting text
- Bright but controlled palette: fresh greens/teals as primary learning colors, warm yellow/orange for rewards, soft blue for progress/info, coral/red for warnings, off-white or warm neutral backgrounds
- Premium contrast balance: do not make it too childish or over-saturated
- Modern sans-serif typography with high readability and friendly weight contrast
- Consistent icon style, expressive progress bars, pill chips, badges, streak counters, and XP indicators
- Use delightful micro-illustrations and mascot moments where suitable
- Use clean spacing and mobile-first alignment
- Every screen must look production-ready, presentation-ready, and visually cohesive

Navigation and product behavior:
- Learner-facing screens should feel energetic, rewarding, and motivational
- Admin-facing screens should stay in the same brand family but become cleaner, denser, and more operational
- All screens are mobile layouts, including admin screens
- Use bottom navigation, floating action emphasis, segmented controls, progress bars, chips, cards, and modal sheets when relevant
- Show realistic states such as empty states, content cards, filter controls, CTA buttons, tabs, and dialogs where appropriate

Learner experience design principles:
- Make learning feel fun, achievable, and habit-forming
- Emphasize streaks, XP, levels, badges, progress, daily goals, and completion states
- Pronunciation screens should feel interactive, confidence-building, and voice-centered
- Quiz screens should feel fast, clear, and rewarding
- Lessons should feel modular, visual, and easy to continue
- History and profile screens should feel reflective and progress-driven, not dull

Admin experience design principles:
- Same visual family, but less playful than learner screens
- More compact information density
- Clear dashboards, metrics, action cards, moderation tools, management lists, and edit flows
- Strong prioritization for status, filters, review actions, and CRUD management
- Use chips, table-like cards, expandable rows, metric cards, and confirmation dialogs in mobile-friendly form

Output instructions:
- Generate a complete set of high-fidelity mobile app mockup descriptions for the following screens
- Keep the design system consistent across all screens
- For each screen, clearly describe layout, hierarchy, components, color use, navigation, and key interactions
- Include meaningful UI copy examples in Bahasa Melayu
- Include states like loading, empty, active, success, warning, and modal moments when useful
- Keep the result suitable for turning into polished UI mockups in Figma or image generation workflows

Create mockups for these learner screens:
1. Splash Screen
2. Login Screen
3. Register Screen
4. Home Dashboard
5. Profile Screen
6. Pronunciation Practice Screen
7. AI Tutor Chat Screen
8. Lessons Screen
9. Quiz Screen
10. Leaderboard Screen
11. Offline Lessons Screen
12. Translation Screen
13. Feedback Screen
14. Pronunciation History Screen
15. Quiz History Screen
16. Notifications Screen

Create mockups for these admin screens:
17. Admin Register Screen
18. Admin Dashboard Screen
19. Admin Profile Screen
20. Manage Phoneme Library Screen
21. Manage Announcements Screen
22. Data Management Screen
23. Manage Lessons Screen
24. Add/Edit Lesson Screen
25. Manage Quizzes Screen
26. Add/Edit Quiz Screen
27. Manage Users Screen
28. Edit User Screen
29. Manage AI Prompts Screen
30. Edit AI Prompt Screen

Important per-screen content guidance:
- Splash Screen: strong brand moment, mascot reveal, warm onboarding energy
- Login/Register: welcoming, simple, polished, confidence-building, not boring form screens
- Home Dashboard: show streak, XP, level, mascot welcome card, latest announcement, learning modules, quick actions, and motivation
- Profile: progress summary, badges, account details, settings, password reset, logout CTA
- Pronunciation Practice: microphone focus, waveform or voice activity visuals, phrase card, pronunciation score, feedback labels, retry/continue actions
- AI Tutor Chat: conversational bubbles, speaking prompts, AI guidance cards, quick-reply chips, session summary
- Lessons: unit cards, progress indicators, categories, difficulty, continue learning CTA
- Quiz: clear question card, answer options, progress stepper, timer or momentum element, success/error states
- Leaderboard: top users, ranks, XP, streak markers, self-position highlight
- Offline Lessons: downloaded lesson cards, storage indicators, remove/download states
- Translation: dual-language input-output card pattern, swap action, suggestion chips, pronunciation support
- Feedback: star rating, category chips, message field, send CTA, success confirmation
- Pronunciation History: score timeline, attempt cards, filters, trend insights
- Quiz History: attempt list, scores, filters, weak-topic highlights, review CTA
- Notifications: announcement cards, priority states, unread/read styling
- Admin Dashboard: analytics cards, overview modules, bottom navigation or segmented admin tabs, recent feedback summary, quick management shortcuts
- Admin Profile: admin identity, role badge, profile edit, security actions
- Manage Phoneme Library: searchable list, phoneme chips/cards, add/edit/delete actions
- Manage Announcements: announcement list, status chips, create/edit/delete actions
- Data Management: dangerous actions, seed/reseed tools, import/export style controls, strong warning design
- Manage Lessons: lesson list, filters, status, add button, edit/delete actions
- Add/Edit Lesson: form-based builder with lesson meta and content sections
- Manage Quizzes: quiz bank list, difficulty/category chips, add/edit/delete actions
- Add/Edit Quiz: form layout for question, answers, correct state, metadata
- Manage Users: user cards, role chips, XP, admin toggle, edit/delete actions
- Edit User: focused edit form for profile and role update
- Manage AI Prompts: prompt library cards, categories, reset-to-default affordance, edit actions
- Edit AI Prompt: text-heavy editor screen that still feels mobile-premium and manageable

Final output format:
- Start with a short overall art direction summary
- Then present the mockups screen by screen
- End with a compact design system summary covering palette, typography, components, iconography, spacing, and mascot usage
```

## Notes

- This prompt is based on the current BMoris screen inventory in `lib/main.dart`.
- It assumes a single visual system shared across learner and admin flows.
- It is optimized for `English prompt + Bahasa Melayu UI copy`.
