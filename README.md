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
