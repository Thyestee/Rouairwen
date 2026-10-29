# Rouairwen — <Lumens>

A healer RPG in the Warcraft universe (Godot 4.7). You are Thyeste, an Undead priest leading the guild **<Lumens>** from Orgrimmar, starting at level 1 with Nightdude (Enhancement shaman) and Raynkoy (Fury warrior).

## Playing

Open `rouairwen/` in Godot 4.7 and run it, or from the command line:

```bash
godot --path rouairwen
```

**Orgrimmar** is the hub, and its menu is a map of the city: the Quest Board in the Valley of Strength, Supplies on the Drag, Dungeons under the Cleft of Shadow (Ragefire Chasm), Recruitment and the Hall of Legends (prestige) in the Valley of Honor, Talents & Spells in the Valley of Spirits, Raids at Grommash Hold and Guild Missions at its War Table in the Valley of Wisdom, and <Lumens>' own Guild Hall. Click a place to go there: the background changes to that place. The Character Sheet and Guild Roster (at the guild hall) sit under the map. The guild's banner, its logo, hangs at the top of the screen.

**Combat**: your guildmates fight on their own; you keep them alive. Hover a party frame and press a spell key to cast on it, or click a frame to target it and click a spell. By default the keys follow the number row, then the Q/E/R/T positions (A/Z/E/R on AZERTY); `F` drinks a mana potion, `Space` pauses, `Esc` cancels a cast. Click an enemy to focus the party's attacks on it. A cast bar sits on top of every party frame and enemy nameplate: the spell being cast, the ability just used, or the next attack filling up (a caster's Frostbolt or Shadow Bolt, a hunter's Auto Shot, a melee swing).

**Damage meter**: in the style of the Details! addon, at the bottom left of every fight: class-coloured bars for **Damage Done**, **Healing Done** (shields' absorbs included) or **Damage Taken**, each with its per-second rate and share. Click its title to switch between them (right-click goes back), and **Current**/**Overall** to see this fight or the whole outing so far; hover a bar for the breakdown by ability.

**Action bar and keys**: in the **Spellbook** (Talents & Spells), drag a spell or use its arrows to move it to another action bar slot. **Key bindings** (in the Spellbook and in Options) rebinds every slot, the mana potion and pause, Shift/Ctrl/Alt combinations included; keys are saved by physical position, so they stay put on any keyboard layout.

**Healing power** works like in WoW: Healing and Spell Damage from gear add up to Thyeste's healing power, and every heal adds a share of it, its coefficient. A direct heal gets its cast time / 3.5 sec (Lesser Heal 71%, Flash Heal 43%), Renew 100% split between its 5 ticks, Penance its channel time / 3.5 split between its bolts (the Lightwell's 20 heals over 10 sec count as one channel, 14% each), Prayer of Healing and Circle of Healing half the usual share on each target, Power Word: Shield 30%. Empowered Healing raises Heal's coefficient. Thyeste is a pure healer: she has no damage spell, and Twin Disciplines raises the healing and absorption of her instant spells instead. Spell tooltips and the Spellbook show what each spell heals with your gear. Healing and Spell Damage on items grow 6% a level like the spells do, so a coefficient is worth as much at every level.

## Activities

| Activity | Party | Levels | Notes |
|---|---|---|---|
| Quests | you + 2 | 1–60, zone matches your level | Procedurally generated, 1–3 fights, choice of reward |
| Dungeons | you + 4 | 10–60 (Ragefire Chasm → Upper Blackrock Spire) | Named Classic loot, Tier 0 from the deepest |
| Raids | you + 9 | 60 | Zul'Gurub, Molten Core, Onyxia, BWL, AQ40, Naxxramas; progress saved per boss |

The quest board offers 6 quests, one of which is always an easy quest whose recommended power is below Thyeste's own. Quests pay a random amount of gold and 4–12 random gear pieces when you turn them in; the gold range, item level and rare/epic odds all scale with the quest's level and difficulty. Rewards are generous: every fight, quest and mission gives 4 times the experience, gold and gear it once did (prices stay the same), and a full guild bank sells what doesn't fit.

Every quest, dungeon run and raid run guarantees one gear piece for a random role (healer, caster, melee or tank), shown before you set out and handed out on completion.

Guildmates have grades from F to SSS+; a bigger guild hall attracts better grades, up to A. A grade is how much a guildmate grows: each one adds the stats their spec fights with, mostly as extra gains every level, so it shows more and more as they level. Fighters grow the stats that give them Attack Power (Strength, Agility, or both for rogues), casters Spell Damage and Intellect, tanks Stamina above all with some Defense, and everyone Stamina. The guild holds 10 members, you included.

**Training** (Recruitment → Training) raises a guildmate one grade at a time: gold up to A, gold and **prestige** past it. Each grade adds stats; B also grants a random perk (critical strike or damage), A a class spell (Recklessness, Slice and Dice, Blizzard...) and S a racial (Blood Fury, Berserking, War Stomp, Will of the Forsaken). Prestige comes only from killing raid bosses, more in the harder raids, and the **Prestige** page ranks <Lumens> against 100 of the Horde's other raiding guilds by all the prestige it has ever earned: the first raids climb dozens of ranks, and reaching #1 takes about 50 hours of raiding at level 60. You are the guild's only healer: recruits are tanks and damage dealers, in every Horde damage and tank spec (Feral Cat and Bear, Subtlety, Survival, Demonology included). Each recruit arrives with 2 spec traits and up to 2 random affixes, good or bad, picked among those that suit their spec (Herculean for Strength users, Brilliant for casters, Ironhide for tanks...); the better their grade, the likelier the affixes are good. Gifted and Stunted change how much their grade gives them.

Guildmates have their own Classic-style talent tree for their spec (one point per level from 10, up to 36). It fills itself with a recommended build unless you edit it on the **Character Sheet**, which also shows everyone's stats (hover a stat's name for what it means), effects and gear.

**Guild Missions** (the War Table) send guildmates away for 5–20 minutes of real time, even with the game closed. Each one shows the experience it gives (30–50% of what your level needs); its spoils, gold, gear or both, are a surprise revealed when the guildmates come back. Each mission's threats are countered by abilities (interrupts, a tank, area damage, a warrior...); a team that counters nothing needs to be 50% stronger than required to be sure of success.

**Options**: windowed, maximized or fullscreen (F11), and the interface size. The interface stretches to fit any resolution and aspect ratio. For testing, **x10** multiplies every experience gain, gold reward and number of gear pieces (quests, dungeons, raids, missions), on top of the usual rates.

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

`launcher/` is a small separate Godot project: **Lumens Launcher.exe** checks the repository's latest GitHub release, and when its tag differs from the installed version it downloads `Lumens-windows.zip`, installs `Lumens.exe` into `%APPDATA%\Lumens Launcher\game` and offers **Play**. Offline, or if GitHub can't be reached, it plays the installed version. Saves stay in the game's own folder, so updates never touch them. Its window shows the guild's banner in front of Orgrimmar's gate, beside the latest release's notes.

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
