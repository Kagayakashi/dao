# AGENTS.md

## Project Purpose

- Dao is a Rails idle RPG MVP with a Chinese cultivator / xianxia theme.
- The core loop is calm passive progression: a signed-in player watches one character gather Qi over time, returns after being away, and manually performs breakthroughs when enough Qi has accumulated.
- Keep the game simple, readable, and modular. Add features in small, testable slices rather than building large systems early.
- Prefer cultivation terminology in code and UI where it improves clarity: Qi for experience, Realm for level, Star for sublevel, Cultivation for progression.

## Commands

- Use Ruby `ruby-4.0.1` from `.ruby-version`.
- Dependencies are Bundler/importmap only. There is no `package.json`; do not add npm/yarn unless explicitly requested.
- Prepare or refresh locally with `bin/setup --skip-server`. Plain `bin/setup` runs setup and then starts `bin/dev`.
- Start development with `bin/dev`, which runs `bin/rails server`.
- Run focused tests with `bin/rails test test/models/character_test.rb` or another test path.
- Full verification is `bin/ci`: setup, RuboCop, bundler-audit, importmap audit, Brakeman, Rails tests, and test seed replant.

## App Shape

- Rails 8.1 app using SQLite under `storage/` for development/test. Production also uses SQLite-backed Solid Cache, Solid Queue, and Solid Cable databases.
- JavaScript uses importmap, Turbo, and Stimulus. Stimulus controllers live in `app/javascript/controllers`.
- Authentication is centralized in `app/controllers/concerns/authentication.rb`; controllers require authentication by default and opt out with `allow_unauthenticated_access`.
- Routes are locale-scoped for `en` and `ru`. The root route is `cultivation#show`.
- Main current routes: root cultivation dashboard, `cultivation/panel`, `cultivation/breakthrough`, leaderboard, public character profiles, current-user inventory, inventory item equip/unequip/drop, users, sessions, passwords, cookie policy, and `/up` health check.
- Keep user-facing strings in both `config/locales/en.yml` and `config/locales/ru.yml`.

## Domain Model

- `User` is authentication-only and has one `Character`. Registration accepts `character_name` and creates the initial character after user creation.
- `Character` is the main game object. Stored database columns are `level`, `sublevel`, and `experience`, but the model aliases them as `realm`, `star`, and `qi`.
- `Character` also tracks `gender`, `total_experience`, `currency`, `reset`, `last_online`, achievements, random game events, event cooldowns, and inventory items.
- Character gender is an enum. Existing and new characters currently default to `male`; profile banners use gender-based images from `app/assets/images`.
- `CharacterAchievement` stores earned achievement keys per character.
- `GameEvent` stores recent random cultivation event history and optional `related_character`. Event `title` and `description` store I18n keys, not display text.
- `CharacterEventCooldown` stores per-event cooldowns plus the global random-event cooldown key.
- `InventoryItem` is equipment. Items are either in exactly one inventory slot or equipped in exactly one equipment slot. Item `name` stores an I18n key such as `iron_dao_blade`, not display text.

## Cultivation Rules

- Qi is generated passively from elapsed time using `Character.base_qi_per_second` and offline multiplier logic.
- `CultivationController#load_cultivation` creates the character if needed, applies offline cultivation, and attempts one random event.
- The cultivation page is wrapped in a Turbo frame and refreshed by `auto_refresh_controller.js` every 10 seconds when the document is visible.
- Gaining Qi does not automatically advance Stars. Breakthrough is a manual action.
- `Character#ready_for_breakthrough?` checks whether current Qi meets `qi_required_for_next_star`.
- `Character#breakthrough!` advances exactly one Star per call, preserves overflow Qi, applies random overflow loss from `breakthrough_overflow_loss_range`, and wraps from Star 9 to Realm + 1 / Star 1.
- Tests currently document repeated manual breakthroughs across a Realm boundary. Do not change to automatic multi-star advancement unless the product direction explicitly changes and tests/UI are updated.
- Default Qi requirements are tuned so Realm 1 takes about one day and Realm 5 takes about one month at the base rate.

## Configuration Pattern

- Current progression tuning is stored as `class_attribute`s on `Character`: stars per Realm, base Qi requirement, Realm/Star growth, Qi per second, multipliers, breakthrough overflow loss, and power scaling.
- Current random-event tuning is centralized in `CultivationEvents::Registry`.
- Prefer extending those existing configuration points before adding new settings systems.
- Keep calculations testable in models/services, not controllers or views.

## Random Events

- Random event orchestration lives in `CultivationEvents::Runner`.
- Event definitions live in `CultivationEvents::Registry::EVENTS`.
- Existing event keys are `good_cultivation_place`, `mysterious_item`, `stranger_cultivator`, and `found_equipment_item`.
- Runner applies Qi deltas, creates `GameEvent` records, updates event cooldowns, and updates the global random-event cooldown.
- Equipment drops are created through `Character#create_inventory_item!` so inventory capacity rules stay in one place.
- Add new events by updating the registry, runner behavior, locale strings, and focused service tests.

## Inventory And Power

- Current equipment kinds are `weapon`, `ring`, and `pendant`.
- Current equipment slots are `weapon`, `ring_one`, `ring_two`, and `pendant`.
- Character power equals cultivation power plus equipped item power.
- `InventoryItem#power_options` is serialized JSON and `inventory_power` sums option values.
- Inventory has `Character::INVENTORY_SLOTS` slots. A character cannot equip items from another character.
- The cultivation dashboard should stay focused on progression. Equipment and inventory management belong on the singular current-user `inventory` page.
- Public character profiles show basic character info, achievements, and equipped items. Only the current user's own profile links to inventory.

## Achievements And Leaderboard

- Achievements are currently defined in `Character::ACHIEVEMENTS` and awarded from `gain_qi` and `breakthrough!`.
- Existing achievements are first Star breakthrough, first Realm breakthrough, and 1,000 total Qi.
- The leaderboard orders characters by `total_experience`, then Realm, then Star, and shows the top 10.

## UI Direction

- This is an idle game. The interface should be quiet and minimal, not an overloaded MMORPG UI.
- Prioritize one main focus: cultivation progress, Realm/Star, Qi, and a small number of meaningful secondary sections.
- Avoid clutter, excessive buttons, constant animations, large text walls, and dense number-heavy panels.
- Visual language: parchment, ancient scrolls, carved stone, wood, subtle gold/dark-brown borders, warm beige panels, soft shadows, small rounded corners.
- Buttons should feel ceremonial: dark brown background, gold border, warm beige text, subtle hover glow.
- Progress bars represent Qi accumulation: stone gray track, jade green or Qi blue fill, gold frame, slow smooth transition.
- Use the existing CSS custom properties in `app/assets/stylesheets/application.css`: dark brown, ancient gold, jade green, warm beige, dark ink, soft gray, Qi blue.
- Keep mobile-first spacious vertical layouts. The player mostly watches progression.
- Existing icons are inline SVGs from `ApplicationHelper#cultivation_icon`; add icons there only when needed.

## Localization

- Maintain both English and Russian locale files for any user-facing UI, event, achievement, item, validation, or flash text.
- The app uses scoped route locale prefixes `(:locale)` for `en|ru`.
- Preserve existing theme terms consistently: Qi, Realm, Star, Cultivation, Breakthrough, Power, Leaderboard.
- Do not persist localized display text in game records. Store I18n keys and neutral metadata, then translate at render time. Character names are the exception because they are player-provided names.

## Testing Notes

- `test/test_helper.rb` uses `fixtures :all` and parallelizes by processor count. Every fixture file must have a real backing table.
- Use `test/test_helpers/session_test_helper.rb` and `sign_in_as(user)` for integration/controller tests that require authentication.
- When changing progression math, update `test/models/character_test.rb`.
- When changing random events, update `test/services/cultivation_events/runner_test.rb`.
- When changing dashboard behavior, update `test/controllers/cultivation_controller_test.rb`.
- Prefer focused test runs during development, then `bin/ci` before considering large work complete.

## Implementation Guidance

- Make the smallest correct change. Avoid speculative abstractions.
- Keep MVP systems modular but not over-engineered. Prefer a model method or small service over a new framework.
- Keep controllers thin: load records, call domain methods/services, redirect/render.
- Do not put progression, event, achievement, or inventory rules directly in ERB.
- Do not add external libraries unless the feature clearly cannot be done with Rails, Turbo, Stimulus, and CSS.
- Be careful with persisted game balance changes; tests encode current assumptions.
- Do not remove manual breakthrough behavior or overflow-loss mechanics without explicit product direction.
- Keep accessibility basics: semantic headings, labels/ARIA where useful, readable contrast, and keyboard-friendly buttons/links.

## Deployment

- `Dockerfile` is production-oriented and precompiles assets with `SECRET_KEY_BASE_DUMMY=1`; it is not the local development path.
- Kamal config is `config/deploy.yml`; production needs `RAILS_MASTER_KEY`.
- Production runs Solid Queue inside Puma via `SOLID_QUEUE_IN_PUMA: true` unless deployment config changes.
