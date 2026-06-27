# Dao

Dao is a small browser-based idle RPG built with Ruby on Rails. The game has a calm Chinese cultivator / xianxia theme: one character slowly gathers Qi over real time, returns later, and performs manual Breakthroughs to grow through Stars and Realms.

The project is an MVP focused on readable idle progression, small meaningful choices, and long-term character growth rather than a dense MMO-style interface.

## Gameplay Overview

The core loop is simple:

* Qi accumulates passively while the player is online or away.
* The player spends accumulated Qi by manually performing a Breakthrough.
* Each Breakthrough advances exactly one Star.
* After Star 9, the next Breakthrough advances the character to the next Realm and returns them to Star 1.
* Overflow Qi is preserved, but a random portion of overflow can be lost during Breakthrough.
* Progression is intentionally slow and idle-friendly, with early Realms taking about a day and later Realms taking much longer at the base rate.

The dashboard stays focused on cultivation state, recent events, and the next Breakthrough. More management-heavy actions live on separate Adventure, Inventory, Event Log, and profile pages.

## Core Mechanics

### Cultivation

Each character has:

* **Qi**: experience used for Breakthroughs.
* **Realm**: the main cultivation level.
* **Star**: the sublevel within the current Realm.
* **Power**: combat and equipment strength.
* **Wen**: common currency.
* **Liang**: rarer premium-style currency earned through limited gameplay sources.

Qi is generated from elapsed real time. Gaining enough Qi does not advance the character automatically; the player must return and choose Breakthrough manually.

### Breakthroughs

Breakthroughs are deterministic advancement actions, not chance-based success checks. If the character has enough Qi for the next Star, a Breakthrough advances one Star and applies the configured overflow Qi loss. This preserves the idle game rhythm while keeping the main progression choice manual.

### Random Events

While cultivating, characters can encounter random events such as:

* Finding a good cultivation place.
* Discovering mysterious items.
* Meeting a stranger cultivator.
* Finding equipment.

Events can grant Qi, create inventory items, or record story moments in the Event Log. Event text is localized and stored through keys instead of persisted display strings.

### Adventures

The Adventure hub contains side activities outside the main dashboard:

* **Temple of Heaven**: claim a daily Qi reward.
* **Sparring**: spend focus to fight opponents and earn rewards.
* **Spirit Expedition**: send the character away for 1, 4, 12, or 24 hours to return with Qi and Wen.
* **Artifact Refinement Hall**: reroll an item's Power options using Wen or Liang.
* **Crier**: read news and announcements.

Spirit Expeditions pause passive cultivation and personal random events while active. Longer expeditions are reduced by 25%, and short expeditions have a small chance to reward Liang.

### Inventory And Equipment

Characters can find and manage equipment. Current equipment kinds include:

* Weapon
* Ring
* Pendant

Equipment can be stored in inventory or equipped in available slots. Equipped item Power contributes to total character Power. Item Power options are generated through the same item power roll system used by random drops and admin grants.

### Events, Profiles, And Leaderboard

The game keeps an Event Log for cultivation, sparring, expeditions, refinements, and random discoveries. Public character profiles show basic character info, achievements, and equipped items. The Leaderboard ranks characters by total Qi, then Realm and Star.

## Implemented MVP Features

* Passive online and offline Qi generation.
* Manual Star and Realm progression through Breakthroughs.
* Overflow Qi preservation with configured overflow loss.
* Random cultivation events.
* Daily reward at the Temple of Heaven.
* Sparring encounters.
* Timed Spirit Expeditions.
* Inventory and equipment management.
* Artifact refinement and item Power rerolls.
* Achievements.
* Public profiles and Leaderboard.
* Event Log and short dashboard Recent Events.
* News/Crier page.
* User registration, temporary onboarding, sessions, and profile completion.
* Admin tools for item grants, Qi adjustments, news posts, and dashboard navigation.
* English and Russian localization.

## Tech Stack

* Ruby 4.0.1
* Ruby on Rails 8.1
* SQLite
* Hotwire: Turbo and Stimulus
* Importmap
* Minitest
* RuboCop, Brakeman, bundler-audit, and importmap audit through `bin/ci`

## Running Locally

Install dependencies and prepare the app:

```sh
bin/setup --skip-server
```

Start the development server:

```sh
bin/dev
```

Run focused tests:

```sh
bin/rails test path/to/test.rb
```

Run full verification:

```sh
bin/ci
```

## Project Status

Dao is a playable MVP and technical experiment. The main goal is to explore idle RPG mechanics, Rails domain modeling, Hotwire interactions, localization, and small modular gameplay systems.

## Screenshots

* Home page

<img width="593" height="1311" alt="image_2026-06-21_12-04-37" src="https://github.com/user-attachments/assets/0faeffe5-2942-42ac-815e-eecc0987a583" />

* Profile

<img width="584" height="1310" alt="image_2026-06-21_12-05-02" src="https://github.com/user-attachments/assets/b09812d6-9391-46ea-9e47-2c4ad6c770d6" />

* Inventory

<img width="595" height="1307" alt="image_2026-06-21_12-05-51" src="https://github.com/user-attachments/assets/f5d2cb17-a535-4458-bcf1-88b7f1ea0c6d" />

* Admin panel

<img width="648" height="598" alt="image_2026-06-21_12-06-24" src="https://github.com/user-attachments/assets/d6bb340f-d798-4e02-9af3-5b1765e5b183" />

<img width="673" height="668" alt="image" src="https://github.com/user-attachments/assets/bdd880ff-53ca-4d42-9cfc-ad0009216a37" />

<img width="686" height="686" alt="image_2026-06-21_12-07-07" src="https://github.com/user-attachments/assets/dcb20d29-4b9a-4d21-9e79-45b866b939d6" />
