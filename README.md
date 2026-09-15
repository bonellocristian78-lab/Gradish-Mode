# Gradish Mode

Fanmade entity mod for DOORS. Client-side, run through an executor.

---

## The only loadstring most people need

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/MainScript"))()
```

That is the mod. It loads the engine, rolls a schedule from the game seed, hides
crucifixes in the furniture, paints Seek red, and spawns entities as you walk.
Everything below is either a piece it loads for you, or a tool for building the
mod rather than playing it.

---

## Every loadstring

### Play

| What | Loadstring |
|---|---|
| **The mod** | `.../MainScript` |

### Build (tools — not for players)

| What | Key | Loadstring |
|---|---|---|
| **Dev console** | F1–F6 | `.../GradishDev` |
| **Config checker** | — | `.../GradishCheck` |
| Every crucifix | 1–5 | `.../CrucifixAll` |
| Plain crucifix | K | `.../CrucifixGiver` |
| Corroded crucifix | H | `.../CorrodedCrucifixGiver` |
| Drawer test | J / H / K | `.../CrucifixTest` |
| Death-screen probe | — | `.../DeathLightProbe` |

### Single entities (summon one, ignore the schedule)

| Entity | Loadstring |
|---|---|
| Retter | `.../RetterV2` |
| Rose Hell | `.../RoseHellRemake` |
| Yeller | `.../Yeller` |
| Rebound | `.../Rebounddd` |
| Corrode | `.../Corrode` |
| Rude | `.../Rude` |
| Silence | `.../Silence` |
| Speedster Purpleist | `.../SpeedsterPurpleist` |
| Blue Hell | `.../BlueHell` |
| Mischievous Light | `.../MischievousLight` |
| Red Seek | `.../RedSeek` |
| Crucifixes in drawers | `.../CrucifixSpawner` |

`...` is `https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main`
every time. In full, one of them looks like this:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/GradishDev"))()
```

**Do not run `GradishDev` and `CrucifixAll` together.** They both listen on the
number keys and you will get a crucifix you did not ask for every time you pick
something from a menu. `GradishDev` does everything `CrucifixAll` does, on F2.

---

## GradishDev — the console

No UI. It prints to the Roblox console and to `gradish_log.txt`, which is a real
file in your executor's workspace folder, so you can read it after the run
instead of screenshotting.

| Key | What |
|---|---|
| **F1** | summon menu — prints the ten entities, press 1–9 or 0 |
| **F2** | crucifix menu — plain, Corroded, Crimson, Violet, Rainbow |
| **F3** | badges — list / wipe all / grant all / revoke all |
| **F4** | dump the live state: room, seed, what is spawned, your health, what you are holding |
| **F5** | despawn every Gradish entity currently out |
| **F6** | toggle the mod's own logging |

Two steps on purpose: the F-key prints the list, the number picks from it. One
key per entity would need twenty bindings and would fight DOORS' own controls.

**F3 → 2 (wipe) is the one that matters.** A badge you already own is remembered
in `DOORS_Custom_Achievements.json`, and an owned badge never shows its popup
again. Without wiping you get exactly one look at each badge, ever — which is
most of why the badges have been so hard to check.

Summoning runs the entity's real script, so what arrives is what the schedule
would have given you: same profile, same mechanics, same achievements. There is
no separate "test" path that could behave differently from the real one.

---

## GradishCheck — what is actually configured

Run it once, read the report. It changes nothing.

It answers the question that has cost the most time here: *I put the image in,
why is the badge showing something else?* There are five places a badge image
can come from and they override each other in a fixed order. GradishCheck prints
the winner for every badge, by name, and says where it came from.

It also catches what fails silently:

- **Two badges sharing an `Identifier`.** The save file stores identifiers, so
  the second badge is marked owned the moment the first is granted and its popup
  never appears again. Nothing warns you — it just stops working after one run.
- **A model URL that 404s.** The entity script loads fine, the spawner gets
  nothing, and you walk an empty corridor with no error.
- **Missing executor functions.** No `getcustomasset` means URL images cannot
  work at all, and it says so by name instead of leaving you guessing.
- **Badges switched off** that you thought were on.

---

## Badge images

Five places, and the **first one with something in it wins**:

1. `Image` on the badge itself, in `AchievementConfig`
2. `Image` on the entity block, in `AchievementConfig` ← what you normally use
3. `ImagesA/<EntityName>` — the file manager
4. `DefaultImage` at the top of `AchievementConfig`
5. nothing, and the popup uses the DOORS icon

An ID typed into `AchievementConfig` beats `ImagesA`. It used to be the other way
round, which meant pasting an ID did nothing whenever an `ImagesA` file existed.

`ImagesA` is for anything you would rather keep out of the config file. One line:

```lua
return "rbxassetid://133397789900538"
return "https://raw.githubusercontent.com/you/repo/main/rose.png"
return "myimages/rose.png"
```

It works out which of the three it is. A URL is downloaded once and handed to
`getcustomasset`; a file path is read straight off your machine and never leaves
it.

## Switching badges off

Three levels, in `AchievementConfig`:

```lua
Enabled = false                            -- nothing in the mod is ever awarded
["Retter"] = { Enabled = false }           -- that entity awards nothing
["Retter"] = { Untouched = false }         -- just that one badge
```

A badge switched off is never built, so it never reaches the queue and never
writes to the save file. Turning it back on later leaves it as unearned as it was
before.

---

## The crucifixes

| Variant | Colour | Beats | Where |
|---|---|---|---|
| plain | — | whatever does not resist | drawers |
| Corroded | green | **Rose Hell** | drawers |
| Crimson | red | Retter, Mischievous Light | `GradishDev` F2 |
| Violet | violet | Yeller, Rude | `GradishDev` F2 |
| **Rainbow** | cycling | **everything** | `GradishDev` F2 |

Only the plain one and the corroded one are findable in the game. The other
three are deliberately kept out of the drawers — the rainbow one beats every
entity in the mod, so finding it would end any encounter it was used on.

Banishing anything with the rainbow crucifix awards **You tried the dev
crucifix**, which is the point of it existing.

Rose Hell resists an ordinary crucifix 85% of the time. The corroded one is the
answer, and it has to be found. Her brother Blue Hell goes down to an ordinary
crucifix first try, every time — which is where you learn what the crucifix is
supposed to feel like, so that her refusing it later lands.

---

## The entities

| Entity | The idea |
|---|---|
| **Retter** | Rush's behaviour, but you cannot outrun him — you hide |
| **Rose Hell** | Resists the crucifix 85% of the time. Find the green one |
| **Yeller** | Loud |
| **Rebound** | Comes back |
| **Corrode** | Slow. Leaves acid that outlives him — the floor is the threat |
| **Rude** | Standalone. Does not use the shared engine |
| **Silence** | Blackout, ten seconds of warning. **Stand still and he cannot touch you** |
| **Speedster Purpleist** | Fast |
| **Blue Hell** | Rose Hell's brother. The closer he gets, the slower *you* get |
| **Mischievous Light** | The red death light |

---

## How the schedule works

Rolled from the game seed, so the same seed gives the same run.

- at least one entity every **15** rooms
- never more often than one every **5**
- nothing spawns while `RushMoving` or `AmbushMoving` is in the workspace —
  the game's own entities get right of way
- entities that have not appeared yet win ties, so a run does not repeat the
  same three

Over 400 simulated seeds: no spacing violations, about 12 encounters per run.

---

## Requirements

- **The repo must stay public.** `game:HttpGet` cannot authenticate, so a private
  repo returns 404 to the executor exactly as it does to a logged-out browser.
  Public means readable, not writable — nobody but you can change anything here.
- Note the capital **M** in `Gradish-Mode`. `raw.githubusercontent.com` is
  case-sensitive and the old lowercase spelling 404s.
- After you push, give it a few minutes. `raw.githubusercontent.com` sends
  `Cache-Control: max-age=300`, so an executor can load the previous version of a
  file for up to five minutes.

## Files

| File | What it is |
|---|---|
| `GradishCore` | the engine — every other script loads it |
| `MainScript` | the entry point, the schedule |
| `AchievementConfig` | every badge's wording, images and on/off switches |
| `GradishDev` | the console |
| `GradishCheck` | the config report |
| `ImagesA/` | one file per entity saying where its picture comes from |
| `*.rbxm` | the models |
