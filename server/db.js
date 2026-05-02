const Database = require('better-sqlite3');
const path = require('path');

const dbPath = process.env.DB_PATH || path.join(__dirname, 'healthapp.db');
const db = new Database(dbPath);

db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    email       TEXT UNIQUE NOT NULL,
    password    TEXT NOT NULL,
    name        TEXT NOT NULL,
    created_at  TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS profiles (
    user_id        INTEGER PRIMARY KEY,
    age            INTEGER,
    sex            TEXT,
    height_cm      REAL,
    weight_kg      REAL,
    activity_level TEXT,
    goal           TEXT,
    updated_at     TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS metrics (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id    INTEGER NOT NULL,
    type       TEXT NOT NULL,
    value      REAL NOT NULL,
    unit       TEXT,
    recorded_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_metrics_user_type
    ON metrics(user_id, type, recorded_at DESC);

  CREATE TABLE IF NOT EXISTS meals (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    name        TEXT NOT NULL,
    kcal        REAL NOT NULL DEFAULT 0,
    protein_g   REAL NOT NULL DEFAULT 0,
    carbs_g     REAL NOT NULL DEFAULT 0,
    fat_g       REAL NOT NULL DEFAULT 0,
    barcode     TEXT,
    recorded_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_meals_user_time
    ON meals(user_id, recorded_at DESC);

  CREATE TABLE IF NOT EXISTS plans (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id       INTEGER NOT NULL,
    template_id   TEXT NOT NULL,
    scheduled_for TEXT NOT NULL,
    notes         TEXT,
    created_at    TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  );

  CREATE INDEX IF NOT EXISTS idx_plans_user_time
    ON plans(user_id, scheduled_for);

  -- ─── Layer 5: Social + gamification ─────────────────────────────────

  CREATE TABLE IF NOT EXISTS friends (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    name        TEXT NOT NULL,
    handle      TEXT NOT NULL,
    record_id   TEXT,
    added_at    TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, handle)
  );
  CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);

  CREATE TABLE IF NOT EXISTS challenges (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    title       TEXT NOT NULL,
    kind        TEXT NOT NULL,
    starts_at   TEXT NOT NULL,
    ends_at     TEXT NOT NULL,
    target      REAL NOT NULL DEFAULT 0,
    created_by  INTEGER,
    created_at  TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS challenge_participants (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    challenge_id  INTEGER NOT NULL,
    user_id       INTEGER NOT NULL,
    joined_at     TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(challenge_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS leaderboard_entries (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    challenge_id  INTEGER NOT NULL,
    user_id       INTEGER NOT NULL,
    score         REAL NOT NULL DEFAULT 0,
    updated_at    TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(challenge_id, user_id)
  );
  CREATE INDEX IF NOT EXISTS idx_leaderboard_challenge
    ON leaderboard_entries(challenge_id, score DESC);
`);

module.exports = db;
