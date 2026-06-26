# AGENTS.md

## Game Idea

- Dao is a Rails idle RPG MVP with a Chinese cultivator / xianxia theme.
- The player controls one cultivator who calmly progresses over real time: Qi accumulates passively, the player returns later, and breakthroughs are performed manually.
- The fantasy is quiet cultivation, small meaningful choices, and long-term growth rather than a dense MMO interface.
- Keep the game simple, readable, and modular. Add features in small testable slices.
- Use theme terms consistently when they improve clarity: Qi for experience, Realm for level, Star for sublevel, Cultivation for progression, Breakthrough for manual advancement, Power for combat/equipment strength, Wen and Liang for currencies.

## Core Gameplay

- Main loop: gather Qi passively, watch cultivation progress, manually Breakthrough when enough Qi exists, repeat through Stars and Realms.
- Secondary loop: use Adventure paths for activities outside the main dashboard.
- Current Adventure paths include Temple of Heaven daily reward, Sparring, Spirit Expedition, Artifact Refinement Hall, and Crier/news.
- The dashboard should stay calm and focused on cultivation state. Put management-heavy interactions on their own pages.
- Event Log is the longer history page. The dashboard shows only a short Recent Events list and links to More events.

## Required Commands

- Use Ruby from `.ruby-version`: `ruby-4.0.1`.
- Dependencies are Bundler/importmap only. There is no `package.json`; do not add npm/yarn unless explicitly requested.
- Prepare or refresh locally with `bin/setup --skip-server`. Plain `bin/setup` also starts `bin/dev`.
- Start development with `bin/dev`, which runs `bin/rails server`.
- Run focused tests with `bin/rails test path/to/test.rb`.
- Full verification is `bin/ci`: setup, RuboCop, bundler-audit, importmap audit, Brakeman, Rails tests, and seed replant.
- Prefer focused tests during development, then broader verification for larger changes.

## Technical Shape

- Rails 8.1 app using SQLite under `storage/` for development/test.
- Production also uses SQLite-backed Solid Cache, Solid Queue, and Solid Cable databases.
- JavaScript uses importmap, Turbo, and Stimulus. Stimulus controllers live in `app/javascript/controllers`.
- Authentication is centralized in `app/controllers/concerns/authentication.rb`; controllers require authentication by default and opt out with `allow_unauthenticated_access`.
- Routes are locale-scoped for `en` and `ru`. Root route is `cultivation#show`.
- Keep user-facing strings in both `config/locales/en.yml` and `config/locales/ru.yml`.
- Do not persist localized display text in game records. Store I18n keys and neutral metadata, then translate at render time. Character names are the exception.

## Main Routes And Pages

- Cultivation dashboard: root route, `cultivation#show`.
- Refreshable cultivation panel: `cultivation/panel`.
- Manual breakthrough: `cultivation/breakthrough`.
- Event Log: `events#index`, paginated at 10 events per page.
- Adventure hub: `adventures#show`.
- Temple of Heaven daily reward: `temples#show`, `temples#pray`.
- Sparring: `sparring#show`, `sparring#create`, `sparring#change_opponent`.
- Spirit Expedition: `spirit_expeditions#show`, `spirit_expeditions#create`.
- Artifact Refinement Hall: `artifact_refinements#show`, `artifact_refinements#reroll`.
- Inventory: `inventories#show`, plus inventory item equip/unequip/drop actions.
- Public character profiles: `characters#show`.
- Leaderboard, news/Crier, users, registration completion, sessions, passwords, cookie policy, `/up` health check, and admin routes also exist.

## Domain Model

- `User` is authentication-only and has one `Character`.
- Registration accepts `character_name` and creates the initial character after user creation.
- New-player onboarding can create a temporary `User` with generated hidden email/password after the player enters character name and gender. Temporary users can complete registration later and receive a configured Qi reward.
- `Character` is the main game object. Database columns are `level`, `sublevel`, and `experience`, but the model aliases them as `realm`, `star`, and `qi`.
- `Character` tracks gender, total Qi, Wen (`currency`), Liang (`donation_currency`), reset count, last online time, achievements, game events, event cooldowns, inventory items, sparring focus, daily reward state, and Spirit Expedition state.
- Character gender is an enum. Profile banners use gender-based images from `app/assets/images`.
- `CharacterAchievement` stores earned achievement keys per character.
- `GameEvent` stores event history and optional `related_character`. `title` and `description` are I18n keys when possible.
- `CharacterEventCooldown` stores per-event cooldowns plus the global random-event cooldown key.
- `InventoryItem` is equipment. Items are either in exactly one inventory slot or equipped in exactly one equipment slot.
- `InventoryItem#name` stores an I18n key such as `iron_dao_blade`, not display text.

## Cultivation Rules

- Qi is generated from elapsed real time using `Character.base_qi_per_second` and offline multiplier logic.
- `CultivationController#load_cultivation` creates the character if needed, completes finished Spirit Expeditions, applies offline cultivation, recovers sparring focus, and attempts one random event when the character is not on an active Spirit Expedition.
- The cultivation page is wrapped in a Turbo frame and refreshed by `auto_refresh_controller.js` every 10 seconds while the document is visible.
- Gaining Qi does not automatically advance Stars.
- `Character#ready_for_breakthrough?` checks whether current Qi meets `qi_required_for_next_star`.
- `Character#breakthrough!` advances exactly one Star per call, preserves overflow Qi, applies random overflow loss from `breakthrough_overflow_loss_range`, and wraps from Star 9 to Realm + 1 / Star 1.
- Do not change manual breakthrough or overflow-loss behavior unless the product direction explicitly changes and tests/UI are updated.
- Default Qi requirements are tuned so Realm 1 takes about one day and Realm 5 takes about one month at base rate.

## Configuration Pattern

- Progression and balance tuning mostly lives as `class_attribute`s on `Character`.
- Current `Character` tuning includes Stars per Realm, base Qi requirement, Realm/Star growth, Qi per second, multipliers, breakthrough overflow loss, power scaling, sparring focus, daily reward, and Spirit Expedition rewards.
- Random event tuning lives in `CultivationEvents::Registry`.
- Prefer extending existing configuration points before adding new settings systems.
- Keep calculations testable in models/services, not controllers or views.

## Random Events And Event Log

- Random event orchestration lives in `CultivationEvents::Runner`.
- Event definitions live in `CultivationEvents::Registry::EVENTS`.
- Current random event keys include `good_cultivation_place`, `mysterious_item`, `stranger_cultivator`, and `found_equipment_item`.
- Runner applies Qi deltas, creates `GameEvent` records, updates event cooldowns, and updates the global random-event cooldown.
- Event Log shows all character events, 10 per page.
- Recent Events on the dashboard intentionally remains short.
- Add new event types by updating event creation logic, locale strings, and focused tests.
- Event localization supports stored keys under `cultivation_events.`, `sparring.`, `artifact_refinements.`, and `spirit_expeditions.`.

## Adventure Systems

- Adventure is the hub for non-dashboard activity links.
- Temple of Heaven gives a daily Qi reward via `Character#claim_daily_reward!`.
- Sparring spends sparring focus to fight or change opponent. It uses `Sparring::Match` and records manual sparring events.
- Spirit Expedition sends the character away for 1, 4, 12, or 24 hours. Passive Qi and personal random events pause while active. Completion grants Qi and Wen. Expeditions longer than 1 hour are reduced by 25%, and only 1-hour expeditions have a low chance of 1 Liang. Completion records a `spirit_expedition` event with duration and Wen gained.
- Artifact Refinement Hall lets the player reroll an owned item’s power options. The item can be in inventory or equipped. Cost is 300 Wen or 1 Liang. Refinement records an `artifact_refinement` event with item name, old Power, and new Power.
- Crier/news shows announcement posts and read state.

## Inventory, Items, And Power

- Current equipment kinds are `weapon`, `ring`, and `pendant`.
- Current equipment slots are `weapon`, `ring_one`, `ring_two`, and `pendant`.
- Character Power equals cultivation power plus equipped item power.
- `InventoryItem#power_options` is serialized JSON and `inventory_power` sums option values.
- Inventory has `Character::INVENTORY_SLOTS` slots.
- A character cannot equip items from another character.
- Equipment drops must be created through `Character#create_inventory_item!` so inventory capacity rules stay centralized.
- Random item power is generated by `InventoryItems::PowerRoll`. Use this service for any feature that needs the same item power roll behavior.
- Inventory management belongs on the singular current-user inventory page. Do not put detailed equipment management on the cultivation dashboard.
- Public character profiles show basic character info, achievements, and equipped items. Only the current user's own profile links to inventory.

## Admin

- Admin access is separate from player authentication and uses `session[:admin_authenticated]`.
- Admin password verification reads `Rails.application.credentials.dig(:admin, :password_digest)` through `Admin::CredentialPassword`.
- Store a BCrypt digest in encrypted Rails credentials.
- Admin panel has separate pages for item grants, Qi adjustments, news posts, and dashboard navigation.
- Admin item grants create one inventory item for any character, placing it in the first free inventory slot.
- Admin Qi adjustments can add or remove Qi and recalculate Realm/Star immediately. This is intentionally separate from normal manual breakthrough behavior.
- Admin-created item names must be I18n keys from `inventory_items.item_keys`; do not store display names.

## Achievements And Leaderboard

- Achievements are defined in `Character::ACHIEVEMENTS` and awarded from `gain_qi` and `breakthrough!`.
- Current achievements include first Star breakthrough, first Realm breakthrough, and 1,000 total Qi.
- Leaderboard orders characters by `total_experience`, then Realm, then Star, and shows the top 10.

## UI And Visual Style

- This is an idle game. The interface should be quiet, minimal, and readable.
- Prioritize one main focus per screen. Avoid overloaded MMORPG-style panels.
- Use spacious mobile-first vertical layouts.
- Visual language: parchment, ancient scrolls, carved stone, wood, subtle gold/dark-brown borders, warm beige panels, soft shadows, and small rounded corners.
- Buttons should feel ceremonial: dark brown background, gold border, warm beige text, subtle hover glow.
- Progress bars represent Qi accumulation: stone gray track, jade green or Qi blue fill, gold frame, slow smooth transition.
- Use existing CSS custom properties in `app/assets/stylesheets/application.css`: dark brown, ancient gold, jade green, warm beige, dark ink, soft gray, Qi blue.
- Existing icons are inline SVGs from `ApplicationHelper#cultivation_icon`; add icons there only when needed.
- Keep accessibility basics: semantic headings, labels/ARIA where useful, readable contrast, and keyboard-friendly buttons/links.

## Localization Rules

- Maintain both English and Russian locale files for all user-facing UI, event, achievement, item, validation, and flash text.
- The app uses scoped route locale prefixes `(:locale)` for `en|ru`.
- Preserve theme terms consistently: Qi, Realm, Star, Cultivation, Breakthrough, Power, Leaderboard, Wen, Liang.
- Do not persist localized display text in game records. Store keys and neutral metadata.
- For event descriptions, prefer metadata keys like `inventory_item_name_key`, `old_power`, `new_power`, `hours`, and `wen` over pre-rendered text.

## Testing Notes

- `test/test_helper.rb` uses `fixtures :all` and parallelizes by processor count.
- Every fixture file must have a real backing table.
- Use `test/test_helpers/session_test_helper.rb` and `sign_in_as(user)` for integration/controller tests requiring authentication.
- When changing progression math, update `test/models/character_test.rb`.
- When changing random events, update `test/services/cultivation_events/runner_test.rb`.
- When changing item power roll behavior, update `test/services/inventory_items/power_roll_test.rb` and item-drop tests if needed.
- When changing dashboard behavior, update `test/controllers/cultivation_controller_test.rb`.
- When changing Adventure links, update `test/controllers/adventures_controller_test.rb`.
- When changing Spirit Expedition behavior, update `test/models/character_test.rb` and `test/controllers/spirit_expeditions_controller_test.rb`.
- When changing Artifact Refinement behavior, update `test/controllers/artifact_refinements_controller_test.rb`.
- When changing event localization, update `test/models/game_event_test.rb`.

## Implementation Guidance

- Make the smallest correct change. Avoid speculative abstractions.
- Keep MVP systems modular but not over-engineered. Prefer a model method or small service over a new framework.
- Keep controllers thin: load records, call domain methods/services, redirect/render.
- Do not put progression, event, achievement, inventory, or reward rules directly in ERB.
- Do not add external libraries unless the feature clearly cannot be done with Rails, Turbo, Stimulus, and CSS.
- Be careful with persisted game balance changes; tests encode current assumptions.
- Do not add backward compatibility code unless there is a concrete need from persisted data, shipped behavior, external consumers, or explicit requirements.
- Do not remove manual breakthrough behavior, overflow-loss mechanics, or dashboard simplicity without explicit product direction.

## Deployment

- `Dockerfile` is production-oriented and precompiles assets with `SECRET_KEY_BASE_DUMMY=1`; it is not the local development path.
- Kamal config is `config/deploy.yml`; production needs `RAILS_MASTER_KEY`.
- Production runs Solid Queue inside Puma via `SOLID_QUEUE_IN_PUMA: true` unless deployment config changes.
