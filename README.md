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

Guildmates have grades from F to SSS+; a bigger guild hall attracts better grades. The guild holds 10 members, you included. You are the guild's only healer: recruits are tanks and damage dealers.

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

## Development tools

```bash
# Balance table: bot-healer win rates, tier odds and the gold/time curve
godot --headless --path rouairwen --script res://tools/balance_sim.gd

# End-to-end smoke test on a throwaway save (add --shots, without --headless, for screenshots)
godot --headless --path rouairwen -- --smoke
```
