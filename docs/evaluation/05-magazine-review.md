# PREVIEW: *Dungeon Crawler Carol: Lair of The Sea Lord*

## The Sea Lord Is Downsizing. The Tactics Need a Raise.

*A neon-soaked 90s cartoon tactics roguelite with the best monster names of the year and a combat engine still waiting for a reason to exist.*

**Platform:** PC (prototype build, commit 78e1a73) · **Developer:** Plague Doctor Game Lab (solo) · **Engine:** Godot 4.7

> **A note on how this review was made:** this is an early prototype, not a finished game. It was also assessed by analysis rather than with a controller in hand: we read its code and data, ran its own test suite, rendered its screens at 1920×1080, and had a bot play 400 of its battles. Everything below about how it *feels* is an informed reading of that evidence, not a couch session. Treat the score as a snapshot of a work in progress.

---

There's a Segway-riding mall cop in this game who fires shouts out of a megaphone. There's a Crypto Bro Bat, a Bored JPEG Ape, a 5 AM Grindset Gargoyle, and a Layoff Executioner whose idea of small talk is "We're a family. Anyway, you're fired." The first boss is an HOA President Golem who fines you because your mailbox is two inches too tall. If *Dungeon Crawler Carol* were judged on its bestiary alone, it would already be one of the funniest things we've seen out of a solo developer this year.

You play Carol: bandana, denim vest, a sword that glows like a nightclub sign. She's crossing four elemental realms (Earth, Air, Fire and, finally, the Sea Lord's underwater boardroom) to rescue her girlfriend, Princess Penny, a pink-haired, tattooed barista who's been kidnapped to power the villain's corporate espresso machine. It's an endearing premise. The final screen, where the two of them high-five over the Sea Lord's flattened body, is pure Saturday-morning joy.

### Looking the part

Visually, *Carol* knows exactly what it wants to be. It's hot magenta, electric cyan and highlighter yellow, all inked in thick black outlines. The title screen looks like it fell out of a 1993 arcade cabinet, in the best possible way. Battles take place on chunky isometric floors with a different texture and palette for each realm, from cracked suburban dirt to the glowing blue grid of the Sea Lord's lair, and the UI matches the art with neon-bordered panels and a glowing "85% HIT" badge whenever you hover over a target.

Up close, though, the seams show. Every character is a single still frame, facing the camera like a trading card, standing on an isometric floor it doesn't quite belong to. Nobody walks; they glide. Nobody dies; they fade. And the vending machines (the game's full cover) are so tall that they regularly swallow the monsters standing behind them.

### The sound of silence

The game is *completely silent*. There isn't a single sound effect or note of music in this build. For a game whose whole personality is 90s arcade bravado, that's like a Saturday-morning cartoon with the TV on mute. Every hit, miss and boss entrance passes in eerie quiet. We'd wager that half of what this game is trying to be is waiting on a sound card.

### How it plays

Structurally, it's *XCOM* by way of *Slay the Spire*. Each realm is a branching map of about 17 nodes. You choose your route through fights, risky hazard events and supply caches, then take on a boss that covers four tiles of the grid. In battle, Carol gets 4 action points a turn:
- moving costs one AP per tile
- attacking costs two
- chugging a RADICAL Energy Drink costs two

Ranged shots hit 85% of the time in the open, 60% against a target behind a crate, and 35% behind a vending machine. It's clean, readable and quick. An enemy turn with three monsters is over in about a quarter of a second.

The problem is that there's not much to *decide*. Melee ignores cover, so the giant Squeaky Foam Mallet is simply the best weapon whenever you're adjacent. The Contractor Nailgun's long range is pointless, because accuracy never drops with distance. And the cover system, the game's tactical selling point, rarely comes up. Enemies don't look for cover; they walk straight at you. In our sampling of 40 generated rooms, about three-quarters of all possible shots were in the open, and fewer than one in twenty-five were against full cover.

The difficulty is lopsided. A bot playing with no tactics at all won *every* one of 40 early regular fights on Medium, usually within four turns. That same bot won only one in five fights against the final boss on Medium, one in twenty on Hard, and none at all on EXTREME, where the Sea Lord can delete Carol in two hits. A thoughtful human will do much better than our bot. But the game never teaches the cover-hugging play that its finale demands, so the last fight is likely to feel like a wall rather than an exam.

There are rough edges, too:
- A small share of highlighted movement tiles near spike traps simply ignore your click.
- The fog of war lets you see straight through solid vending machines.
- There's no undo, no pause menu, no settings screen and no controller support.

### What's worth fighting for

None of this is unusual for an early prototype, and the foundations are sturdier than its silence suggests:
- It boots in under a second and holds a locked 60 frames per second.
- It runs a 152-point automated test suite that covers everything from save files to Penny's rescue.
- Its monster and weapon data is driven from a single table, so adding content is cheap.
- The writing (the flavour text, the hazards, the boss barks) has a real voice.

What it needs now isn't more stuff. It's a sharper turn: enemies that use cover and telegraph their attacks, a couple of abilities that create real dilemmas, sound, and frames of animation. Oh, and a new name. *Dungeon Crawler Carol* is one letter away from a famous, trademarked book franchise, and that's a fight no tiny studio wants.

---

### PROS
- Hilarious, instantly readable corporate-satire monsters
- Bold, cohesive neon 90s art direction; superb title and ending art
- Clear UI, with a live hit-chance badge and colour-coded ranges
- Rock-solid tech: fast, stable and heavily tested
- A warm, queer-friendly rescue story

### CONS
- No audio of any kind
- No animation; units glide and fade
- Too few meaningful decisions per turn; cover rarely matters
- Trivial early fights, a brick-wall final boss
- No settings, pause menu, undo or controller support
- A title that's an IP problem waiting to happen

### VERDICT
***Dungeon Crawler Carol* has the jokes, the look and the plumbing of a cult hit. What it doesn't have yet is the tactical heartbeat. Give it sound, motion and an enemy that fights back with its brain, and this could be one to watch.**

## PREVIEW SCORE: 5 / 10
*Prototype build, assessed through analysis. The score reflects potential and current state, not a finished product.*
