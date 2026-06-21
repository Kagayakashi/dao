# DooGame

DooGame is a small **browser-based Idle RPG** inspired by Chinese cultivation fantasy stories (*xianxia*), especially worlds similar to *Battle Through The Heavens*.

The project was created as a **technical experiment** and a way to explore how an idle game can be built using modern Ruby on Rails tools.

The main goal was not to build a full game, but to experiment with game mechanics, backend logic, and frontend tools while creating a working MVP.

## What Was Implemented

The MVP includes several core idle game systems:

* Passive **offline Qi generation** (experience gained while away)
* **Dual progression system** — characters gain **Qi** (experience) over time, Qi is used to increase **Stars** (sub-levels), and after reaching enough Stars the player can attempt to advance to the next **Realm** (main level)
* Manual **Breakthrough** system with success/failure chance
* Risk of losing Qi during failed breakthroughs
* Random world events with positive or negative outcomes
* Random **PvP encounters** between players
* Random item discovery events
* Basic equipment system
* Long-term idle progression system — progression is intentionally slow, with early cultivation Realms taking around **24 days** to complete, while higher stages can take **months**, focusing on long-term character growth rather than fast progression

## Purpose of This Project

This project was mainly built to experiment with:

* Building an **Idle RPG** gameplay loop
* Working with **Hotwire**
* Practicing Ruby on Rails architecture
* Testing service objects and domain logic
* Trying browser-based game mechanics in Rails

The idea was to quickly build a playable MVP and understand how these systems feel in practice.

## Tech Stack

* Ruby
* Ruby on Rails
* Hotwire
* SQLite
* HTML / CSS / JavaScript

## Project Status

Project is **finished in MVP state**.

There are currently **no plans to continue development**.

The main objective was achieved:

* build a small playable idle game
* test Rails tools in practice
* experiment with game-oriented architecture

This repository stays as a completed experiment and learning project.

## Screenshots
* Home page

<img width="593" height="1311" alt="image_2026-06-21_12-04-37" src="https://github.com/user-attachments/assets/0faeffe5-2942-42ac-815e-eecc0987a583" />

* Profile

<img width="584" height="1310" alt="image_2026-06-21_12-05-02" src="https://github.com/user-attachments/assets/b09812d6-9391-46ea-9e47-2c4ad6c770d6" />

<img width="595" height="1307" alt="image_2026-06-21_12-05-51" src="https://github.com/user-attachments/assets/f5d2cb17-a535-4458-bcf1-88b7f1ea0c6d" />

* Admin panel

<img width="648" height="598" alt="image_2026-06-21_12-06-24" src="https://github.com/user-attachments/assets/d6bb340f-d798-4e02-9af3-5b1765e5b183" />

<img width="588" height="662" alt="image_2026-06-21_12-06-48" src="https://github.com/user-attachments/assets/efe93600-57e1-4757-9bc2-4cbd39520e3f" />

<img width="686" height="686" alt="image_2026-06-21_12-07-07" src="https://github.com/user-attachments/assets/dcb20d29-4b9a-4d21-9e79-45b866b939d6" />
