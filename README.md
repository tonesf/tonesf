# Recipe Formatter

An iOS app that lets you forward recipes from Instagram, websites, or any text source and displays them in a clean, structured format with rich media support and flexible unit conversion.

## How it works

1. **Share** any recipe — from Safari, Instagram, or paste raw text — via the iOS Share Sheet
2. **Backend** fetches the content, extracts recipe data using Claude AI, and returns structured JSON
3. **App** displays ingredients, steps, images/videos, and lets you toggle between imperial and metric

## Project structure

```
backend/          Python/FastAPI backend
  app/
    main.py       FastAPI entry point
    services/     Fetcher, extractor, Claude client, pipeline
    models/       Pydantic schemas

RecipeApp/        iOS app (SwiftUI + SwiftData, iOS 17+)
  project.yml     xcodegen spec — run `xcodegen generate` to create .xcodeproj
  RecipeApp/      Main app target
  ShareExtension/ Share Extension target
```

## Quick start

### Backend

```bash
cd backend
cp .env.example .env
# Add your ANTHROPIC_API_KEY to .env

pip install .
uvicorn app.main:app --reload
```

Test it:
```bash
curl -X POST http://localhost:8000/parse \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.allrecipes.com/recipe/8652/crispy-fried-chicken/"}'
```

### iOS app

Prerequisites: Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
cd RecipeApp
xcodegen generate
open RecipeApp.xcodeproj
```

Before building:
1. In `project.yml`, set `DEVELOPMENT_TEAM` to your Apple Developer Team ID
2. Replace `com.yourname` throughout with your actual bundle ID prefix
3. In **Xcode → Signing & Capabilities**, register the App Group `group.com.yourname.recipeapp` on both targets
4. In the app's Settings tab, enter your Mac's LAN IP as the backend URL (e.g. `http://192.168.1.10:8000`)

## Features

- **Share Extension** — appears in every app's share sheet; parses URLs and text
- **Instagram support** — scrapes Open Graph tags (title, caption, image, video)
- **Schema.org shortcut** — detects JSON-LD Recipe data on recipe websites for fast, accurate parsing
- **Unit conversion** — toggle imperial ↔ metric per recipe; fractions display as ¼, ½, ⅓ etc.
- **Servings scaler** — stepper scales all ingredient quantities proportionally
- **Rich media** — image carousel and inline video via AVKit
- **Favorites & search** — swipe to favorite, search by name, sort by date or title
- **Offline storage** — all recipes stored locally via SwiftData in a shared App Group container
