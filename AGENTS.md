# AGENTS.md

## Commands

- Use Ruby `ruby-4.0.1` from `.ruby-version`; dependencies are Bundler-only (`Gemfile.lock`), with no `package.json` or Node install step.
- Prepare or refresh a local checkout with `bin/setup --skip-server`; plain `bin/setup` runs setup and then execs `bin/dev`.
- Start development with `bin/dev`, which is just `bin/rails server`.
- Full repo verification is `bin/ci`; it runs `bin/setup --skip-server`, `bin/rubocop`, `bin/bundler-audit`, `bin/importmap audit`, `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`, `bin/rails test`, then `env RAILS_ENV=test bin/rails db:seed:replant`.
- Run focused Rails tests as `bin/rails test test/models/user_test.rb` or another test file path, after `bin/setup --skip-server` has prepared SQLite databases.

## App Shape

- This is a Rails 8.1 app using SQLite files under `storage/` for development/test; production also uses SQLite-backed Solid Cache, Solid Queue, and Solid Cable databases.
- JavaScript is importmap/Hotwire (`config/importmap.rb`, `app/javascript/controllers`); add JS packages with `bin/importmap`, not npm/yarn.
- Authentication is centralized in `app/controllers/concerns/authentication.rb`; controllers are authenticated by default and opt out with `allow_unauthenticated_access`.
- Current domain models are `User`, `Session`, and `Character`; `Character` belongs to `User` and has progression/currency columns from `db/migrate/20260618082447_create_characters.rb`.
- Routes currently define `session`, `passwords`, and `/up`; there is no root route even though `Authentication#after_authentication_url` falls back to `root_url`.

## Testing Gotchas

- `test/test_helper.rb` uses `fixtures :all` and parallelizes by processor count, so every fixture file must have a backing table.
- The current suite fails because `test/fixtures/game_events.yml` exists but there is no `game_events` table/model/migration; fix or remove that fixture before expecting `bin/rails test` or `bin/ci` to pass.
- `test/test_helpers/session_test_helper.rb` provides `sign_in_as(user)` for integration tests by creating a `Session` and signed `session_id` cookie.

## Deployment

- `Dockerfile` is production-oriented and precompiles assets with `SECRET_KEY_BASE_DUMMY=1`; it is intended for Kamal or manual container runs, not local dev.
- Kamal config is `config/deploy.yml`; deploy secrets must include `RAILS_MASTER_KEY`, and production runs Solid Queue inside Puma via `SOLID_QUEUE_IN_PUMA: true` unless that config is changed.

## Visual Design
# Minimal Interface
This is an idle game.

UI must remain simple.

The player mostly watches progression.

Avoid:

- cluttered screens
- too many buttons
- unnecessary menus
- large text walls

Prioritize:
- readability
- calm visual appearance
- easy navigation

Less is better.

# Prestige Through Simplicity

The interface should feel elegant rather than flashy.

Examples:

Bad:

- overloaded MMORPG interface
- too many numbers everywhere
- constant animations

Good:

- one cultivation progress bar
- clear rank display
- subtle visual effects

The player should feel progression naturally.


# Color Palette

Primary colors:

- Dark Brown      #2C1810
- Ancient Gold    #D4AF37
- Jade Green      #3A7D44
- Warm Beige      #F5E6C8
- Dark Ink        #1E1E1E
- Soft Gray       #777777

Accent colors:

- Qi Blue         #6FA8DC
- Fire Red        #B33939
- Spirit Purple   #7E57C2
- Heaven Gold     #FFD700

# UI Component Style
All components must share the same design language.

Panels should look like:

- parchment paper
- ancient scrolls
- carved stone tablets
- wooden panels

Style:

- rounded corners: small
- borders: subtle gold or dark brown
- background: beige or dark parchment
- shadow: soft

Avoid:

- glassmorphism
- modern flat gradients
- neon borders

# Buttons

Buttons should look ceremonial.

Style:

- background: dark brown
- border: gold
- text: warm beige
- hover: slight glow
- padding: medium
- corners: subtle rounding

Buttons should feel handcrafted.

Not modern app buttons.

Progress Bars

Progress bars represent Qi accumulation.

Style:

- background: stone gray
- fill color: jade green or qi blue
- border: gold frame
- animation: slow smooth fill

Never use flashy animations.

# Layout Rules

Use spacious layouts.

Never overcrowd UI.

Preferred spacing:

- large margins
- clear sections
- single focus per screen
- centered content
- vertical layout

This is an idle game.

Player attention should go to progression.

## Project Overview

- Build a first simple MVP version of an Idle RPG game with a Chinese cultivator / xianxia theme.
- The game is focused on passive character progression. The player gains Qi over time, including while offline. Qi is used as experience and increases the character’s cultivation progress.

## Core Theme Terms
Use cultivation-themed terminology in the code and UI where reasonable:
- Experience = Qi
- Level = Realm
- Sublevel = Star
- Character progression = Cultivation

## Models

# User
Model for authentication, just login.

# Character
Every user have one character. Character is main thing to use. Character model already exist in codebase.


## MVP Requirements
# Character Progression

Each character has:

- realm — main level
- star — sublevel inside the current realm
- qi — accumulated experience

Progression rules:
- Characters generate Qi passively over time.
- Every 9 Stars equals 1 Realm
- Qi increases Stars
- If character got XP more than required for next star, calculate how much stars he will get, not XP lose on overflow.
- make configurable expierence/currency multipliers.
- Create special thing - BonusEvents, that gives additional multipliers for Period.
When a character gains enough Qi for the next Star:
- increase star
- subtract required Qi
When star exceeds 9:
- increase realm
- reset star to 1

# Example:

Dou Qi Stage, 1★
Dou Practitioner 9★
...
Great Dou Master 9★
Dou King 1★


## Technical Requirements
- Project should be MODULAR, to disable and easy implement new features.
- Project should be CONFIGURABLE, to easy change some core foundamental things.
- Keep MVP simple.
- Do not over-engineer.
- Avoid external libraries unless absolutely necessary.
- Use clear domain names related to cultivation.
- Separate progression logic from controllers/routes/UI.
- Put cultivation calculation in a dedicated service/model method.
- Logic must be testable without depending on UI.
- Achievments.
- Ladderboard on different things, but first of all by total experience (qi).
- Basic animations CSS + Turbo + Stimulus.
- Simple UI, mobile first, looks like native, less buttons, preferebly that user see less options, to not overconfuse.