# BytePulse AI — Developer Intelligence Suite

BytePulse AI is a real-time developer intelligence hub built with Flutter, powered by **Gemini 3.6 Flash**, **Firebase Auth**, **Cloud Firestore**, and **Firebase Cloud Messaging (FCM)**. It curates, synthesizes, and grounds technical release notes, engineering blogs, and infrastructure alerts tailored to specific engineering roles (AI/ML, DevOps, FinOps, Systems Architect).

---

## Key Architecture & Features

### 1. Gemini 3.6 Flash Live Streaming & Grounding
- **Streaming Responses**: Interactively streams AI responses using `gemini-3.6-flash` via HTTP chunked parsing.
- **Grounded Context**: Injects structured article summaries, code snippets, and custom topics into the LLM context prompt for precise technical Q&A.

### 2. Live Ingestion Feed & Canonical Link Resolution
- **Multi-Source RSS Ingestion**: Ingests release feeds from Google Cloud, AWS Developer Blog, Hacker News Engineering, and GitHub Release feeds.
- **Canonical Link Safety**: Ensures all article links navigate to live, verified domain targets (`https://cloud.google.com/blog`, `https://aws.amazon.com/blogs/aws`, `https://github.blog`, `https://news.ycombinator.com`).
- **URL Launcher Validation**: Validates external link launchability using `canLaunchUrl`. Automatically catches invalid or non-200 mock URLs and fallback-redirects to parent feeds with a user-friendly preview notice.

### 3. Firebase Auth & Web Demo Auth Simulation
- **Google OAuth**: Supports Firebase Google Sign-In for cloud profile synchronization.
- **Web Demo Auth**: Includes a built-in "Demo / Test Sign In" session state handler (`MockFirebaseUser` with profile `Test Developer` / `dev@bytepulse.ai`) to enable seamless testing in web preview mode (`localhost:8080`) without requiring OAuth domain whitelisting.
- **Riverpod State**: Synchronizes authentication state across `authUserProvider`, automatically unlocking Firestore cloud saved articles and preference sync.

### 4. Cloud Firestore Sync & FCM Push Notifications
- **Firestore Stream Sync**: Syncs bookmarks, saved items, custom technical topics, and role preference vectors (`ai_ml`, `devops`, `finops`, `arch`) to Cloud Firestore collections.
- **FCM Push Notifications**: Configured for high-priority technical alerts and quiet-hours schedule controls.

---

## Quality Assurance & Audit Summary

- **Static Analysis**: `flutter analyze` completed with **0 compilation errors**.
- **Web Demo Verification**: Fully tested on Flutter Web Server (`http://localhost:8080`) with active web session management, role filtering, article modal deep-dives, and live Gemini streaming.

---

## Getting Started

### Environment Prerequisites
- Flutter SDK 3.x+
- Dart SDK 3.x+

### Launching Web Preview Locally
```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY \
  --dart-define=GEMINI_MODEL=gemini-3.6-flash
```

---

*BytePulse AI — Built for high-velocity software engineering teams.*
