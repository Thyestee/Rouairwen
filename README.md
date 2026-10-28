# Rouairwen — <Lumens>

A healer RPG in the Warcraft universe (Godot 4.7). You are Thyeste, an Undead priest leading the guild **<Lumens>** from Orgrimmar, starting at level 1 with Nightdude (Enhancement shaman) and Raynkoy (Fury warrior).

## Playing

Open `rouairwen/` in Godot 4.7 and run it, or from the command line:

```bash
godot --path rouairwen
```

**Orgrimmar** is the hub: quest board, dungeons, raids, recruitment, supplies (the Drag), guild hall upgrades, the guild roster and bank, and your talents.

**Combat**: your guildmates fight on their own; you keep them alive. Hover a party frame and press a spell key to cast on it, or click a frame to target it and click a spell. Keys follow the number row, then the Q/E/R/T positions (A/Z/E/R on AZERTY). `F` drinks a mana potion, `Space` pauses, `Esc` cancels a cast. Click an enemy to focus the party's attacks on it.

## Activities

| Activity | Party | Levels | Notes |
|---|---|---|---|
| Quests | you + 2 | 1–60, zone matches your level | Procedurally generated, 1–3 fights, choice of reward |
| Dungeons | you + 4 | 10–60 (Ragefire Chasm → Upper Blackrock Spire) | Named Classic loot, Tier 0 from the deepest |
| Raids | you + 9 | 60 | Zul'Gurub, Molten Core, Onyxia, BWL, AQ40, Naxxramas; progress saved per boss |

The quest board offers 6 quests, one of which is always an easy quest whose recommended power is below Thyeste's own. Quests pay a random amount of gold and 1–3 random gear pieces when you turn them in; the gold range, item level and rare/epic odds all scale with the quest's level and difficulty.

Every quest, dungeon run and raid run guarantees one gear piece for a random role (healer, caster, melee or tank), shown before you set out and handed out on completion.

Guildmates have grades from F to SSS+; a bigger guild hall attracts better grades. The guild holds 10 members, you included. You are the guild's only healer: recruits are tanks and damage dealers, in every Horde damage and tank spec (Feral Cat and Bear, Subtlety, Survival, Demonology included). Each recruit arrives with 2 spec traits and up to 2 random affixes, good or bad.

Guildmates have their own Classic-style talent tree for their spec (one point per level from 10, up to 36). It fills itself with a recommended build unless you edit it on the **Character Sheet**, which also shows everyone's stats (hover a stat's name for what it means), effects and gear.

**Guild Missions** (the War Table) send guildmates away for 5–20 minutes of real time, even with the game closed, for gold, experience or gear. Each mission's threats are countered by abilities (interrupts, a tank, area damage, a warrior...); a team that counters nothing needs to be 50% stronger than required to be sure of success.

**Options**: windowed, maximized or fullscreen (F11), and the interface size. The interface stretches to fit any resolution and aspect ratio.

## WoW icons

Spell, talent, buff and potion icons use the real WoW icons when they are present in `rouairwen/assets/icons/`, and drawn stand-ins otherwise. They are Blizzard's art, so they are not in the repository (the folder is git-ignored) and should not be redistributed. To download them from Wowhead's icon CDN:

```bash
godot --headless --path rouairwen --script res://tools/fetch_icons.gd
```

## Building the Windows exe

The "Windows Desktop" export preset builds a single `Lumens.exe` (game embedded) into `build/windows/`, which git ignores. It leaves out the WoW icons and the dev tools; a shared copy downloads the icons into the player's own data folder on first launch, and uses the drawn icons when offline.

```bash
godot --headless --path rouairwen --export-release "Windows Desktop" ../build/windows/Lumens.exe
```

Share the exe through a GitHub Release rather than committing it. It isn't code-signed, so Windows SmartScreen may warn on first launch ("More info" → "Run anyway").

## Launcher (auto-update)

`launcher/` is a small separate Godot project: **Lumens Launcher.exe** checks the repository's latest GitHub release, and when its tag differs from the installed version it downloads `Lumens-windows.zip`, installs `Lumens.exe` into `%APPDATA%\Lumens Launcher\game` and offers **Play**. Offline, or if GitHub can't be reached, it plays the installed version. Saves stay in the game's own folder, so updates never touch them.

Publishing a new release is all it takes for every launcher to pick it up, as long as the release keeps a `Lumens-windows.zip` asset with `Lumens.exe` inside. Drafts and pre-releases are skipped (GitHub's "latest release" ignores them), so they can be tested before friends get them.

```bash
godot --headless --path launcher --export-release "Windows Desktop" "../build/launcher/Lumens Launcher.exe"

# Test without touching a real install: update into a scratch folder, print the result, quit
godot --headless --path launcher -- --check-only --install-dir=/tmp/lumens-test
```

## Development tools

```bash
# Balance table: bot-healer win rates, tier odds and the gold/time curve
godot --headless --path rouairwen --script res://tools/balance_sim.gd

# End-to-end smoke test on a throwaway save (add --shots, without --headless, for screenshots)
godot --headless --path rouairwen -- --smoke
```
