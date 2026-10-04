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
| DOORS optimizer (max graphics, less lag) | `.../DoorsOptimizer` |
| Hellish Time Ever (K = an entity, spam it) | `.../HellishTimeEver` |
| Noise: a TV above the door, a blue tape, a hammer, a crucifix | `.../Noise` |
| Noise 90: every "-90" as a Noise (`_G.Type = "A-90"`, ...), all in one | `.../Noise90` |
| DOORS' walk, run, crouch and jump in any game | `.../DoorsAnimations` |
| Universal Custom Assets: animator with Studio controls (Ctrl + U I O) | `.../UniversalAssets` |
| The same, obfuscated | `.../UniversalAssets.obf` |

### Build (tools — not for players)

| What | Key | Loadstring |
|---|---|---|
| **Dev console** | F1–F6 | `.../GradishDev` |
| **Config checker** | — | `.../GradishCheck` |
| Every crucifix | 1–5 | `.../CrucifixAll` |
| Chain crucifix (works on every custom entity) | — | `.../Crucifix` |
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
| Honcho | `.../Honcho.lua` |
| Honcho V2 | `.../HonchoV2.lua` |
| J-518 | `.../J-518` |
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
| **F1** | summon menu — prints the entities, press 1–9, 0 or - |
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

## The chain crucifix

```lua
_G.CrucifixType = "Guiding"   -- or "Curious", "Fail", "Glitch"; leave the line out for Guiding
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Crucifix"))()
```

Penguin's crucifix model, used up on the first try, with the chain ritual Honcho
has: the circle opens under the entity, eight chains take it and drag it into a
hole in the floor. It works on Honcho, J-518, every Gradish entity and anything
else built on Vynixu's spawner. DOORS' own entities are run by the server and a
ritual on your screen cannot save you from them, so it does not try.

| Type | Colour | What happens |
|---|---|---|
| `Guiding` | blue | the entity is dragged down and gone |
| `Curious` | yellow | the same, in yellow |
| `Fail` | blue, then red | the entity tears the chains, breaks the crucifix, lands and carries on |
| `Glitch` | blue, then violet | Penguin's crucifix being eaten by DOORS' Glitch from the top: its upper half is made of Glitch pixels, aligned to the crucifix, that pop out a step or three and snap back; a cyan scan line sweeps it. Every second or two a short, clean glitch hit (the grip jumps, red and cyan ghosts). Always fails; its pixels blow apart. On Honcho V2 they slam into him and he transforms |

Any crucifix also fails on an entity that resists — Speedster Purpleist always,
Rose Hell 85% of the time. Honcho's fail has its own animation, also shipped as
`HonchoCrucifixFail.rbxmx` to open in Studio's Animation Editor.

The ritual lives in `CrucifixRitual`, which Honcho, Honcho V2, J-518 and `Crucifix`
all load.

## Honcho V2

```lua
_G.CrucifixType = "Glitch"    -- optional: "Guiding", "Curious", "Fail" or "Glitch"
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/HonchoV2.lua"))()
```

Honcho with the crucifixion rebuilt. `Honcho.lua` is still there, unchanged. Every
setting works the same way (`_G.Speed`, `_G.Size`, `_G.Rebounds`...).

- Every animation lasts two seconds longer. The light lifts him and he hangs in
  it with his arms open; the chains arrive one at a time and sway; a halo turns
  behind the crucifix. At the end he pulls himself half out of the hole and
  everything goes quiet, as if he made it — then the last pull.
- The fail is two seconds longer too: he gathers himself before the last tear.
- The jumpscare and the sink at the end of the run last two seconds longer.
- With the **Glitch** crucifix he breaks free and lands; the crucifix's pixels
  slam into him and DOORS' real Glitch (`ReplicatedStorage.Entities.Glitch`)
  appears over him for an instant. Then sixteen seconds in clear beats:

  | seconds | what happens |
  |---|---|
  | 0 – 1 | the hit arches him and time stops for half a second |
  | 1 – 5.4 | on his knees he fights it; DOORS' Glitch look climbs him like a wave, feet to chest |
  | 5.4 – 10.2 | he clutches his head as the wave reaches his face, which becomes a broken screen |
  | 10.2 – 13.5 | he gets up with his arms open while a crown of Glitch blocks assembles over his head, one block at a time |
  | 13.5 – 14.3 | silence: lights almost out, no sound, he does not move |
  | 14.3 – 16 | he roars and everything comes back |

  The glitch hits land on a beat that speeds up like a heartbeat — the pose
  freezes, a slice of him slides sideways in red and cyan, one joint snaps —
  with calm in between. Blocks peel off only where the wave is passing. Then he
  hunts you again as a Glitch, crown and broken face included, 25% faster.

The three animations are also shipped for Studio's Animation Editor:
`HonchoV2Crucifix.rbxmx`, `HonchoV2CrucifixFail.rbxmx`,
`HonchoV2CrucifixGlitch.rbxmx`. They hold the keyed poses; the trembling, the
glitch stutter and the wandering are added by the script.

## Hellish Time Ever

```lua
_G.Time   = 0      -- optional: seconds before it starts
_G.Random = true   -- optional: false = entities only come with K
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/HellishTimeEver"))()
```

A DOORS mode. **K** brings an entity, every time: spam it and they keep coming.
With `_G.Random` left on, they also come on their own, one every 20 to 60
seconds. `_G.Time` delays the start by that many seconds from the loadstring.

- Everything on screen is DOORS' own, cloned while you play: the font, the red
  flash, the jumpscare text, the vignette, the modifier panel, the sounds (Dread's
  boom and ambience, the modifier-added sound), the camera shake.
- **The start:** black screen, red flash with Dread's boom, HELLISH TIME EVER in
  the font of DOORS' "YOU ARE DEAD" text in moving black and white, DOORS' knob
  badge under it, then DOORS' modifier panel with **+666%** knobs.
- **Every entity:** red flash, camera kick, the room's lights red for a moment,
  and a counter at the top: `HELLISH x7   SPEED 150`.
- **The hell rises:** each entity makes the rooms redder and darker, the sound
  more muffled and Dread's ambience louder, up to the 12th.
- A bag, not dice: nine entities (Rush, Ambush, A-60, A-120, Scribble, Bash,
  Blitz, Honcho V2, J-518), never the same one twice in a row, and the bag fills
  up again by itself. Speed climbs from 60 to 250 (100 = Rush).
- Everything is downloaded at the start, so spamming K spawns at once. One that
  cannot be loaded is skipped and the next comes instead.
- It gives nothing away: it switches off `CrucifixGiver`, `CorrodedCrucifixGiver`
  and `CrucifixAll`, mutes the mod's badges while it runs, and Honcho V2 comes
  without his crucifix and badges.

## Noise

```lua
_G.CrucifixGive = true   -- optional: false = no crucifix
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Noise"))()
```

Noise (B-90), with the kit's own TV, Noise, B-90, hammer, crucifix circle and
animations (`assets/noise/NoiseKitV2.rbxm`).

- **The TV:** the kit's TV (no feet, no cart) hanging from the ceiling on its
  arm, above the way out of your room, facing in. Under a high ceiling its bar
  stretches up to it; under a low one the TV comes down. Static on its screen.
  It moves to each new room until you look at it.
- **Look at it for 3.5 s:** the world turns blue and the tape plays **on the
  TV's screen** (its own `VideoGui`), not on yours. You hear it from the TV and
  you can keep moving.
- **When the tape ends:** Noise crawls out of the screen itself (its Emerge
  animation starts with the body lying in the screen; since this TV hangs above
  the door, its root comes down with the fall) and walks your steps at your
  speed minus 0.1 (20 → 19.9). Stand still and it is 3.5 slower, but it never
  stops (its pause icon shows). Leave it more than 70 studs behind and it
  screams (the tape's scream), turns bluer and fast-forwards at your speed + 8
  until it is close again. It catches you at 4.5 studs: its jumpscare, and you
  die.
- **Its own way out:** when it goes (you got away, it got you, or the TV
  broke) it freezes, its tape goes bad (torn poses, jumps, see-through ghosts,
  missing pieces) and it shuts off like an old TV: a bright line, a dot,
  nothing.
- **The hammer** lies on the floor of the room, never in a wall, under a
  table or against one. In DOORS only DOORS' own prompt shows. Use it and a
  cutscene plays, with black bars:
  1. low on the floor, you walk to it, bend down and take it;
  2. you toss it once in the air and catch it, the camera going round you;
  3. you turn and point at the TV: the camera pulls back while it narrows,
     the TV stays the same size and the room stretches around it;
  4. the wind-up from below, colours draining; the throw from behind, with a
     punch and a blur;
  5. it flies end over end in slow motion, the camera turning round it, and
     hits the screen: a blink of stillness, the glass bursts;
  6. the TV swings on its arm, sparking; dust falls from the ceiling as the
     arm starts to give, then it tears out: the TV falls on its back with the
     hammer still in it, and the arm, its bar and its plate fall too, now that
     nothing holds them; the TV bounces, and its back and buttons come off in
     a cloud of dust and glass.

  Before the tape nothing comes out any more; during the tape Noise never
  comes; during the chase Noise freezes as you pick the hammer up, and goes
  its own way out in front of you.
- **The crucifix:** `_G.CrucifixGive = true` (the default) puts one in your
  inventory (the mod's own, from `CrucifixRitual`; two planks if it cannot be
  loaded). It works only when Noise **catches** you with it in your hand (any
  crucifix, the game's too): instead of dying you watch, with your own camera,
  free to move:
  1. a chain shoots from the crucifix and catches it; it **rewinds** back away
     from you, its own walk played backwards, with the tape's rewind sound;
  2. your crucifix flies up above it, the circle (the kit's Repentance) opens
     under it, and it rises into its rest pose from the kit: arms wide;
  3. **B-90 is pulled out of its head** along one smooth curve while the
     circle divides in two and slides under B-90, and the body it wore turns
     white (the kit's Noise without B-90); the crucifix moves above both, a
     chain down to each;
  4. on their chains both fight, each with its own animation. Noise (keyframed
     on the kit's joints, easing from pose to pose) pulls forward against the
     chains, throws itself back, twists one way and the other, kicks and
     claws; while B-90 is torn out of it it is thrown back, rigid and shaking,
     then hangs limp for a moment before it fights. B-90 thrashes, breathes,
     and twice lunges at you before its chain yanks it back;
  5. three pulls, both at once: Noise is jerked down, arms up, B-90 shows its
     STOP; then both go down into their circles, Noise reaching up, a flash,
     the circles close, the TV goes dark.
- The kit and the tape are downloaded once into
  the executor's `Noise` folder. Without the kit a plain TV, Noise and hammer
  stand in. Every setting is at the top of the script (`_G.Noise = { ... }`).

## Noise 90

```lua
_G.Type = "A-90"     -- which one (below); B-90 if left out
_G.Setup = "Auto"    -- where its TV is (below)
_G.Disc = "Look"     -- B-90 only: "Look" or "DontLook"
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Noise90"))()
```

One script, every "-90" (the entities you must stand still for) as a version of
Noise. Each starts from a TV; its tape is tinted in its colour, with its face in
the middle of the picture (where the light is while it loads, and big at the end);
Noise comes out in its colours, with its face on its head. Only B-90 can be
crucified. `B-90` here is exactly the `Noise` script (hammer and crucifix included).

Faces, colours and ways come from the wikis (Interminable Rooms fanmade, Interminable
Rooms, INTERMINABLE FEVER); G-90 has no picture there, so its face is drawn from its
description.

| Type | What sets the tape off | What it does |
|---|---|---|
| `B-90` | you stare at it (disc "Don't Look": it plays by itself, do not look) | walks your steps; hammer, crucifix |
| `C-90` | it plays only while you look **away** | walks only while you stand still, stops when you move |
| `Ransom//90` | you open a drawer | red, Ransom in its tape. Every drawer: it climbs out, comes for you, hits 90, walks backwards into its TV |
| `A-90` | you come close | 10 rebounds in the dark: its face on your screen (freeze, or 90), then out of the TV across the room and back in a streak, throwing every locker about; in one, it has you |
| `X-90` | you come close | 40 rebounds, four at a time, 50x faster; lockers **and** tables |
| `G-90` | you stare at it | out of a paper (checks the tables) or out of a computer (checks the tables, fakes it is gone for 5 s, comes back behind you and checks the lockers) |
| `Pix-90` | you stare at it | creeps in pixel jumps; its pixel face pops up: move while it is there and its mouth opens wider (the wiki's three frames); the third time it jumps at you, 90 |
| `Trollface-90` | you stare at it | its face on your screen: stop moving, or the Rage Guy jumps all over it, 90, and no more healing. Pass: red, white, gone, with A-90's sound |
| `XTrollface-90` | you come close | inverted, bloodshot, a giggle first, flashes yellow: if you do **not** move, 90 to 100 |
| `S-90` | you stare at it | dark room, its TV glows one colour; its buttons (redn, geen, bule) while three of it circle you: click its colour. Wrong: "LEARN THE COLORS OF THE RAINBOW. FOOL." and a kick (`Kick = false`: you die) |
| `XS-90` | you come close | inverted, red pupils: six colours, much less time, or hide |
| `X-60` | you stare at it | its own tape (its six yellow faces, two orbiting the middle one); then it rushes back the way you came, faster and faster, loud static, and stays 9 s in your room slowly going down: hide |

| Setup | Where the TV is |
|---|---|
| `Ceiling` | above the door on its ceiling arm (the hammer only here) |
| `Table` | on the Archives' wooden table by the far wall: plug it in (the socket is on the nearest wall), turn its antenna (until then: NO SIGNAL) |
| `Cart` | the Stairwell's TV cart with its disc player: plug it in; the discs (one per type, two for B-90) lie in the room; take one, put it in. Once it is out, hold **Eject**: the disc jumps out and it is pulled back into its TV |
| `Pedestal` | a pedestal by the far wall, the TV on the floor: pick it up, put it on, plug it in, tune it. The pedestal may give way (`PedestalFall`): the TV falls, cracks, and keeps playing |
| `Teller` | the Teller's screen (it says NOW SERVING until the tape covers it) |
| `Computer` | a computer on a table (G-90's): plug it in |
| `Screens` | the room's own screens (the Archives' monitors, the Teller's, the terminals): every one plays the tape, and Noise comes out of them in pieces — a leg from one, an arm from another — that fly together |

A remote lies in every room: take it, and it pauses the tape or the entity for
3 seconds, 4 times.

**The discs** (`Cart`): each lies in its case — front cover, back cover (the
wiki's words and how to survive), spine, the disc and its label, a clear lid. Take
one and **right-click** it (or **Inspect**, `R`, on the floor; a button on touch
screens) to look at it close: drag to turn it, wheel to zoom, open the case, flip
it. A disc may be **dirty** (the player reads it, says `DISC ERR` and gives it back:
hold **Wipe** while you inspect it) or **scratched** (the tape skips, and what
comes out is angrier); `DiscWear = false` keeps them clean, `"dirty"` or
`"scratched"` makes them all so. The player: its tray slides out, the case goes
down on it and opens, the disc goes in; its display says `NO DISC`, `READ`,
`PLAY 00:07`, `PAUSE`, `DISC ERR`, `EJECT`; **Pause** (`F`) holds the tape for 2.5 s
(then 10 s to rest); once it is out, **Eject** throws the disc out and pulls it back
into its TV. The TV has a power light (red in standby, green on) and switches on
and off like an old tube.

**Its screens look like DOORS'**: Oswald and cream text, dark brown buttons with a
cream edge, DOORS' title font for NO SIGNAL, MOVE, X-60 and FOOL; the back of a disc,
when you inspect it, is a page of DOORS' Journal (handwriting in brown ink, its
border and smudge). The player's display and Ransom's note keep their own screen
fonts. The cart is a copy of DOORS' own, and DOORS' prompt gate kept switching its
prompts back on (they flickered and could not be held): the copy now loses the
tags that bring it there (`CartProp`, `GatedPrompt`, `ItemHolder`). Its buttons free
the mouse (`Modal`) only while their screen is open: Roblox frees it even for a
disabled ScreenGui, and in DOORS the camera stopped turning as soon as the script ran.

`Auto` takes the type's own setups at random, `Screens` in the Archives; with
any setup, the room's own screens play the tape too. The TV is a little bigger
or smaller each time (`TVScale`). Every setting is at the top of the script
(`_G.Noise90 = { ... }`). The props come from `assets/noise/NoiseWorld.rbxm`,
the faces from `assets/noise/Wiki_*.png` (the wikis'; G-90's `Face_G90.png`), the tinted tape from
`assets/noise/NoiseFramesGray_*.jpg`.

Still to come: the troll laugh (any sound id in `Laugh`; A-90's sound sped up
without one). C-90 is on no wiki: it is the "contrary" one for now.

## DOORS animations in any game

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/DoorsAnimations"))()
```

Two steps, the first only once:

1. **Run it inside DOORS**, in a run. A copy of your character appears in front
   of you and plays DOORS' animations while they are written down, thirty
   samples a second. Stand still until it says it is done. They are saved in your
   executor's workspace as `DoorsAnimations.lua`.
2. **Run it in any other game**: it reads that file and your character moves
   like in DOORS.

Why not just play DOORS' animation IDs: Roblox plays an animation only in games
owned by whoever uploaded it, and DOORS' belong to the LSPLASH group (Forward is
17186586680, Idle 4341150436, both LSPLASH's). Elsewhere they never start. Step
2 loads no animation: it moves the joints itself, so no game can refuse it.

It does what DOORS' `Main_Game.Movement` does: Idle always on; Forward always
on with weight and speed = your speed / 15, which is DOORS' run; **C** to crouch
(and slide, when faster than 20 studs/s); Jump and Land; Seated; Interact on a
prompt. **F4** switches it off and on. Only you see it — everybody else keeps
seeing your normal animations. R15 characters only, like DOORS'.

## Universal Custom Assets

```lua
_G.UniversalAssets = {              -- all optional, these are the defaults
    Combo = { "U", "I", "O" },      -- hold Ctrl and type these: opens / closes the panel
    ComboTime = 2,                  -- seconds allowed between those keys
    PlayKey = "P",                  -- Ctrl + P: play / pause, also with the panel closed
    FreeCamKey = "F",               -- Ctrl + F: free camera on / off
    UIScale = 1.2,                  -- size of the panel on a PC
    MobileScale = 0.8,              -- size of the panel on a phone
    MobileButtons = "auto",         -- the phone bar: "auto", true (always) or false
    MoveSnap = 0.5,                 -- studs   (0 = free)
    RotateSnap = 15,                -- degrees (0 = free)
    ScaleSnap = 0.05,               --         (0 = free)
    FreeCamSpeed = 24,              -- studs per second; Shift = a quarter
    LookSpeed = 0.25,               -- degrees per pixel, right mouse in the free camera
    OpenTime = 0.6,                 -- seconds to open / close doors and drawers
    Folder = "UniversalAssets",     -- where projects are saved
    SelfUrl = "...",                -- what Copy's loadstring loads (this script)
    Project = nil,                  -- a scene (what Copy puts here): built at start
    AutoPlay = false,               -- with Project: it plays as soon as it is built
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/UniversalAssets"))()
```

An animator, in Italian, the same on a PC and on a phone. **Ctrl + U I O** opens
it (on a phone: **UCA** at the top); the same combo or the **X** closes it and
locks the mouse back; **_** folds it to its title bar; **?** opens the guide,
which also opens by itself until you press **Ho capito**.

Four tabs, in the order you use them; each starts with a line saying what to do.
Always under them: the timeline, **Play** (play / pause), **Stop**, **Loop**,
**Velocità** (1x, 0.5x, 0.25x, 2x) and what is happening. Above them, **< >**
picks the thing you are working on (the **Telecamera** first), **Togli** removes it.

- **1 Aggiungi** — **Inserisci** a preset: DOORS' Glitch, Screech, Spider, Dread,
  Figure; the door, wardrobe, drawers, bookcase, table, chandelier, plant, clock or
  painting of the room you are in; a few custom morph models. **Cerca** searches
  Roblox's Creator Store (the Studio toolbox) with preview, author and number of
  animations; **Seek, Rush, Ambush, Figure, Halt, Eyes, Screech, Jack** are one tap
  away; **Solo animati** hides models without animations, **Altri risultati** loads
  more. Tap a result to insert it: its scripts are taken out, its animations
  converted when needed. **Usa ID** inserts an asset ID or a `.rbxm` URL.
- **2 Muovi** — Studio's tools: **Seleziona / Sposta / Scala / Ruota** (Ctrl+1..4)
  with arrows, dots and rings, **Griglia** (snapping), **Locale / Mondo**. Click (or
  tap) a model to select it; **Davanti a me** brings it in front of you,
  **Posiziona** drops it where you click (tap). **Duplica**, **Diventa lui** (morph:
  it becomes your body and walks with its own animations), **Annulla / Ripeti**
  (Ctrl+Z / Ctrl+Y), **Camera libera** (Ctrl+F: WASD, E/Q, Z/X zoom, right mouse to
  look; on a phone its own arrows and a finger to look).
- **3 Anima** — the easy way: put the thing where it starts and press **1. Parte da
  qui**; drag it where it arrives and press **2. Arriva qui**: it gets there in the
  seconds written next to it (3). Press 2 again for more stretches. A model with a
  run / walk animation looks where it goes and runs (**Corsa auto** turns on by
  itself; idle when it stands). With the **Telecamera** selected, 1 and 2 use the
  free camera: on Play it flies through those points, as in a DOORS cutscene.
  **Percorso**: with the panel open, red dots in the world show the way, with a
  numbered dot on each key. Below, the full keys: **Tempo**, easing and direction
  (**Smooth** curves through all the keys), and what a key starts: an **Anim** (with
  speed; the same one on the next key keeps going), a **Suono**, an **Azione** —
  open / close / open reverse (doors, drawers: anything on a hinge or a rail),
  lights off / on / flicker, hide / show, particles on / off / burst, and the
  effects `shake`, `flash`, `say <text>`, `room flicker`, `room lights off`,
  `room lights on`, `room shatter` (DOORS' own). **+ Chiave**, **Aggiorna**,
  **Elimina**, **Vai**; tap a key in the list to edit it.
- **4 Scena** — **Salva** / **Carica** (the executor's `UniversalAssets` folder),
  **I tuoi progetti** (tap one to load it), **Copia** (a loadstring with the whole
  scene inside: pasted in the executor, it builds it again and plays it), **Nuova
  scena** (press twice: everything goes).

**On a phone** the panel fits the screen (scale 0.8) and its pages scroll; drag
it by its title, the top bar by `::`. Texts too long for a button get smaller
instead of spilling out. DOORS' own buttons stay where they are.

Animations owned by the game's owner (in DOORS: LSPLASH) play normally. Any
other one is converted when the model is inserted: its KeyframeSequence is
downloaded and played by the script, joint by joint. A KeyframeSequence inside
the model works the same way. Nothing is uploaded anywhere; only you see it.

`UniversalAssets.obf` is the same script obfuscated with
[Prometheus](https://github.com/prometheus-lua/Prometheus) (Luau): the Medium
preset's steps — strings encrypted, names mangled, constants and numbers hidden,
anti-tamper — without its VM step (Vmify). Vmify miscompiled this script at random
(about one build in five crashed or misbehaved) and made it about 3.5 times slower.
Regenerate it after every change to `UniversalAssets`, and run the tests on it.

## DOORS optimizer

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/DoorsOptimizer"))()
```

For DOORS itself, with or without the mod: run it in a match and turn graphics
up to 10. It lowers nothing you can see; it takes away work the GPU does for
things you can't. Measured on the DOORS dump (7 rooms loaded, the player in 5):

| What costs | In the dump | With the optimizer |
|---|---|---|
| Lights casting shadows — with DOORS' Future lighting each one redraws the scene | 43 | the 8 nearest the camera: the room you're in keeps all of its own; fewer if your FPS drop (see AUTO) |
| Fill lights (`LowQualityDisable`) | 78 | only the ones within 60 studs |
| Parts casting shadows | 952 | 827 — knobs, wall strips, ceiling details, plant dirt, plates and papers stop |
| Rooms drawn | 7 | the one you're in, 2 behind and 2 ahead |

- **F8** switches it off and on, so you can compare. **F7** shows or hides the
  FPS panel. Running it again replaces the old copy.
- **AUTO.** On a slow PC the F6 test gave 15 FPS with 38 lights casting
  shadows, 14 with 8, and 22 with none: Roblox already skips the shadows of far
  lights, so the ones that cost are the nearest. How much they cost depends on
  the machine and the room, so the optimizer measures it while you play: below
  `AutoFps` (40) it takes the shadows off one more nearby light every second;
  above 52 for 3 seconds it gives one back. If they drop again right away, it
  waits 30 seconds before trying again, so shadows don't flicker on and off.
  `AutoFps = 0` turns it off.
- The panel also shows the video card (GPU) and processor (CPU) times, the
  script time and the draw calls. The times include waits, so they are for
  comparing, not on their own.
- **F6** runs a 9-second test: stand still and don't turn the camera. It
  measures FPS off, on with all 8 lights, and on with no light casting
  shadows, then puts everything back and leaves the table in the panel.
- It only changes `Light.Shadows`, `BasePart.CastShadow`,
  `LocalTransparencyModifier` and `Enabled` on the `LowQualityDisable` lights —
  the dump shows DOORS' own scripts never write the first three on rooms, and
  set the fourth only once, when graphics are low. Far rooms are hidden on your
  screen only: they stay solid and in place. F8 puts everything back.
- Room loads are spread over several frames, so there is no spike when a door
  opens. `setfpscap`, if your executor has it, lifts the 60 FPS cap to 240.
- Settings, before the loadstring:
  `_G.DoorsOptimizer = { ShadowLights = 6, RoomsBehind = 3, FpsCap = 0 }`
  (every one is listed at the top of the file).
- It cannot make Roblox draw faster than your GPU can. If a single room at
  graphics 10 is already too much, it helps but will not fix it — F8 shows how
  much it gains on your machine.

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
| **Honcho** | Standalone. Runs the rooms like Rush; hold a crucifix and he is chained into the floor |
| **Honcho V2** | Honcho with a longer, more dramatic crucifixion, and the Glitch crucifix that transforms him |
| **J-518** | Standalone room boss. A black and white vortex opens in the ceiling, ten seconds of warning, then he knocks on every wardrobe. Be inside one |

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
| `CrucifixRitual` | the chain ritual and the crucifix itself, shared by `Crucifix`, Honcho, Honcho V2 and J-518 |
| `HonchoCrucifixFail.rbxmx` | Honcho's fail animation as a KeyframeSequence, for Studio |
| `HonchoV2Crucifix*.rbxmx` | Honcho V2's three crucifix animations (banish, fail, glitch), for Studio |
| `GradishDev` | the console |
| `DoorsOptimizer` | the DOORS optimizer |
| `HellishTimeEver` | the Hellish Time Ever mode |
| `HellishGradient` | the moving black and white of its modifier row and title |
| `HTE/` | the models Hellish Time Ever summons |
| `DoorsAnimations` | DOORS' character animations, recorded in DOORS and played anywhere |
| `Noise` / `Noise90` | Noise (B-90); every "-90" as a Noise, `_G.Type` |
| `assets/noise/` | Noise's kit, tape and sheets; Noise 90's props kit, grey sheets and faces |
| `UniversalAssets` / `.obf` | the animator for DOORS' things and custom assets, readable and obfuscated |
| `GradishCheck` | the config report |
| `ImagesA/` | one file per entity saying where its picture comes from |
| `*.rbxm` | the models |
