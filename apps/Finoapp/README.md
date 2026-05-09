# Finoapp

Personal finance tracker. React Native (TypeScript) — Android + iOS.

## Status

v0 placeholder. The MVP shows a current balance and a list of transactions
from in-memory mock data; the **+ Add transaction** button is wired to a
stub. Persistence, real auth, sync, and a backend API are deliberately out
of scope for this commit.

## Stack

| | |
|---|---|
| React Native | 0.85.x |
| React | 19.x |
| TypeScript | 5.8 |
| Build | Metro + Hermes |
| Cross-platform | Android + iOS |

## Build & run

```bash
cd apps/Finoapp

# Install JS deps
npm install

# Start the Metro dev server
npm start

# In another terminal, build & launch on a connected device / emulator
npm run android      # requires Android SDK + a running emulator
npm run ios          # requires macOS + Xcode + CocoaPods
```

For iOS first time only:
```bash
cd ios && pod install && cd ..
```

## History

Originally a separate repo (`AmericanGroupLLC/Finoapp`, Ionic 3 + Cordova
sidemenu boilerplate from 2018). Imported into the monorepo with full
2-commit source history preserved as the merge commit's second parent
(`git log --all` to see it), then rewritten as a fresh React Native + TS
scaffold.

## Layout

```
apps/Finoapp/
  android/          # Native Android shell (Gradle Kotlin DSL)
  ios/              # Native iOS shell (Xcode project + Podfile)
  __tests__/        # Jest tests
  App.tsx           # Root component (Finance Tracker placeholder UI)
  index.js          # RN entry point
  package.json
  tsconfig.json
  metro.config.js
  babel.config.js
```
