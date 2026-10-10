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
| Noise 90: every "-90" (A-404 and R-90 too) as a Noise (`_G.Type = "A-90"`, ...), all in one | `.../Noise90` |
| Noise 90, all of them: a new one every 10 s (the others stay), out at once, every disc in the Journal | `.../Noise90All` |
| DOORS' walk, run, crouch and jump in any game | `.../DoorsAnimations` |
| Morph: anybody's avatar on you (`_G.User = "name"`), only you see it | `.../Morph` |
| New Seek: DOORS' Seek with another body (`assets/seek/NewSeek.rbxm`); `_G.Type = "Glitch"`: made of DOORS' Glitch (its purple, cube texture and particles, pink light), glitched eyes, hands of cubes | `.../NewSeek` |
| Honcho Seek: DOORS' Seek is Honcho (Seek's animations made for his body), Honcho's sounds (DOORS' chase song kept), the kit's eyes and hands on the walls | `.../HonchoSeek` |
| Interminable Rooms: the 675 entities of its wiki in a panel (name and GIF, click to spawn; a tab where they cannot hurt you), or one with `_G.Entity = "A-60"`; their faces, GIFs, sounds and what they do | `.../InterminableRooms` |
| Surprise: Honcho runs through the rooms like Rush (Seek's run made his) | `.../HonchoRush` |
| Surprise: a huge Honcho walks to your room, booming; a wardrobe will not hide you, a bed will | `.../HonchoGiant` |
| Surprise: Noise rebounds like Ambush, 3 to 6 times, faster each time | `.../NoiseAmbush` |
| Surprise: Seek's eyes on the walls of your room; look at them and Seek's hands come out of the floor | `.../SeekEyes` |
| Surprise: the Listener, a new blind one (like Figure, animated): it hears your steps, crouch or hide | `.../Listener` |
| Surprise: a mass of Glitch's cubes rushes through the rooms in jerks, twice | `.../GlitchRush` |
| Surprise: your Shadow does what you did, 4 s later: don't stop moving | `.../Shadow` |
| Surprise: a blue ghost like Halt, "TURN AROUND" | `.../TurnAround` |
| Surprise: dark room, "psst" behind you: look at it (like Screech) | `.../Psst` |
| Surprise: A-60, A-15, A-35, A-100, A-200 and E-22 one behind the other | `.../EntityTrain` |
| Hotel-: the Washroom, down a staircase beside door 0001: a laundry, the key of B-02, a big attic past it, the key of B-03 (DOORS' models, doors, locks, drawers, items, Guiding Light, hiding; no entities) | `.../Washroom` |
| Hotel-: today's DOORS walk, crouch and sounds (doors, hits, footsteps) | `.../ModernHotel` |
| MONOCHROME: VER at the next door (its own walk, sounds, lights, kill, radar), with its creator's permission; `_G.VER` = `"White"`, `"Glitch"`, `"Noise"` (out of a TV) | `.../Monochrome` |
| Scanners: DOORS' radar (Nokia) or the NVCS tablet (`_G.Scanner = { Type = "Tablet" }`) | `.../ObjectScanner` |
| Lucky Bottle: a Starlight Bottle that brings luck through DOORS' Admin Panel (needs it) | `.../LuckyBottle` |
| Unlucky Bottle: a Starlight Bottle that brings bad luck (no more wardrobes, 1 health...; needs the Admin Panel) | `.../UnluckyBottle` |
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
| 3rr0rbu2h (Errorbush): a broken Ambush, 5-10 rebounds, two forms | `.../Errorbush` |
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
_G.RandomPos = true  -- optional: the TV anywhere in the room, on a battery
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Noise90"))()
```

One script, every "-90" (the entities you must stand still for) as a version of
Noise. Each starts from a TV; its tape is tinted in its colour, with its face in
the middle of the picture (where the light is while it loads, and big at the end);
Noise comes out in its colours, with its face on its head. `B-90` here is
exactly the `Noise` script (hammer and crucifix included).

**Every one can be crucified**: you get a crucifix with every type. Hold it when
it is about to get you (it catches you, its face is on your screen, S-90's wrong
colour, A-404's kick) and instead it is chained, rewound and pulled down into
its circle, in its own colour. Only B-90 also has B-90 torn out of it, into a
second circle.

**More than one at once**: run it again and the one before stays; they go on
together. To end them all: `getgenv().__Noise90.stop()`. The kits and the files
are read and built once, by the first one; the next ones reuse them, so a new
one no longer freezes the game when it appears.

Faces, colours and ways come from the wikis (Interminable Rooms fanmade, Interminable
Rooms, INTERMINABLE FEVER); G-90 has no picture there, so its face is drawn from its
description. R-90 is on no wiki: it was made here from a design sent on a Discord
server (its face, its body and its black spots are cut from it), and so was its way.

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
| `A-404` | you stare at it | Interminable Rooms' glitched one (its wiki's head, faces and static). Docile, blue: it stands between you and the way on, an invisible wall across the room, its mouth moving: "This is a glitched server, please join a new one." It goes in 20 to 40 s. Try to get past it (or open the next door) and it is angered, red: its head and its face come apart all over your screen, swap, and it kicks you with `ERROR CODE 404`, hiding or not (`Kick = false`: you die) |
| `R-90` | you come close | red with black spots, white eyes, a red and yellow toothy grin. **Red light, green light**: it stands a little before the door with its back to you. GREEN LIGHT (the room green): walk. "..." (amber, a click): it is about to turn. RED LIGHT (the room red): it turns round and grins; move and it is on you, 90, then it goes back to its place and the game goes on. Get through the door and it has lost; after 6 rounds it gives up |

Every one is in its own colours, body and all: the kit's Noise is blue (B-90 in
it), and only B-90 keeps that blue now.

| Setup | Where the TV is |
|---|---|
| `Ceiling` | above the door on its ceiling arm (the hammer only here) |
| `Table` | on the Archives' wooden table by the far wall: turn its antenna (until then: NO SIGNAL) |
| `Cart` | the Stairwell's TV cart with its disc player: the discs (one per type, two for B-90) lie in the room; take one, hold it, put it in. Once it is out, hold **Eject**: the disc jumps out and it is pulled back into its TV |
| `AVCart` | the disc player on a school AV cart: grey steel, three shelves with a lip, casters, a push handle, the TV strapped on top, tapes underneath, a power strip, PROPERTY OF THE HOTEL |
| `Console` | the disc player in a 70s walnut TV console: speaker cloth behind slats, brass knobs, a doily under the TV. **Open** its doors before a disc goes in |
| `Luggage` | the disc player on the hotel's brass luggage cart: red carpet, brass posts and bar with hooks, the TV on a strapped suitcase (its luggage tag says which one it is), the player on a vanity case |
| `Pedestal` | a pedestal by the far wall, the TV on the floor: pick it up, put it on, tune it. The pedestal may give way (`PedestalFall`): the TV falls, cracks, and keeps playing |
| `Teller` | the Teller's screen (it says NOW SERVING until the tape covers it) |
| `Computer` | a computer on a table (G-90's) |
| `Screens` | the room's own screens (the Archives' monitors, the Teller's, the terminals): every one plays the tape, and Noise comes out of them in pieces — a leg from one, an arm from another — that fly together |

There is no plug and no remote any more: the TV is on as it is (with `RandomPos`,
once its battery is in).

**The discs** (`Cart`): each lies in its case — front cover, back cover (the
wiki's words and how to survive), spine, the disc and its label, a clear lid. Take
one and it is a real item in your inventory, its cover for its icon; hold it to put
it in the player. **Click** or **right-click** it in your hand (or **Inspect**, `R`,
on the floor; a button on touch screens) to look at it close: drag to turn it, wheel to zoom, open the case, flip
it. The player reads every disc (no more dirty ones and no more `DISC ERR`); one may
be **scratched** (the tape skips, and what comes out is angrier); `DiscWear = false`
or `"clean"` keeps them clean, `"scratched"` makes them all so. The player: its tray slides out, the case goes
down on it and opens, the disc goes in; its display says `NO DISC`, `READ`,
`PLAY 00:07`, `PAUSE`, `EJECT`; **Pause** (`F`) holds the tape for 2.5 s
(then 10 s to rest); once it is out, **Eject** throws the disc out and pulls it back
into its TV. The TV has a power light (red in standby, green on) and switches on
and off like an old tube.

**The Noise Journal**: a book in your inventory (with its icon) every time you run
the script. Every disc you find is written in it and kept in the executor's
folder (`Noise/Journal.txt`), from one run to the next: open it (DOORS' Journal,
two pages) and pick a tape to read its page: its picture, what it is, how to
survive, how many times and when you first found it. The ones you have not found
yet are `???` under a black bar.

Inspecting a disc: its covers and its label read the right way up; the back is a
page of DOORS' Journal with the entity's picture taped on it (the wiki's face; for
B-90 the kit's Noise itself, for C-90 and Ransom the game's own faces), and the
writing is as big as the page lets it be. Noise only walks while it goes somewhere:
standing still, it holds its step (no more walking on the spot).

**Its screens look like DOORS'**: Oswald and cream text, dark brown buttons with a
cream edge, DOORS' title font for NO SIGNAL, MOVE, X-60 and FOOL; the back of a disc,
when you inspect it, is a page of DOORS' Journal (handwriting in brown ink, its
border and smudge). The player's display and Ransom's note keep their own screen
fonts. The cart is a copy of DOORS' own, and DOORS' prompt gate kept switching its
prompts back on (they flickered and could not be held): the copy now loses the
tags that bring it there (`CartProp`, `GatedPrompt`, `ItemHolder`). Its buttons free
the mouse (`Modal`) only while their screen is open: Roblox frees it even for a
disabled ScreenGui, and in DOORS the camera stopped turning as soon as the script ran.

`Auto` takes the type's own setups at random (`Cart` being any of the four
carts), `Screens` in the Archives; with any setup, the room's own screens play the
tape too.

**`_G.RandomPos = true`** (any capitals, or `RandomPos = true` in `_G.Noise90`):
the TV (its table, its cart, its pedestal, its computer) stands anywhere in the
room instead of by the far wall, out of the way of the doors, looking into the
room, on a battery: a 6 V lantern battery lies somewhere in the room; take it and
put it in the box on the TV's side (its lid shuts, the TV comes on). With it, `Auto` never takes the ceiling or the room's own screens (B-90, whose
only setup is the ceiling, gets one of the carts).

**Never in a wall**: a table, a cart, the Teller, the pedestal (and the TV lying
by it) only stand where their whole shape is clear of the walls and of the room's
furniture, by the far wall or (`RandomPos`) anywhere in the room seen from its path;
a table turns along the room when that is the only way it fits. Where nothing fits
(the Luggage cart is 5.4 wide), it waits for the next room where it does, so
nothing comes out of a wall any more.

**`Noise90All`**: every type, one after another, the quick way to have them all.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Noise90All"))()
```

Each one's TV stands anywhere in the room (`RandomPos`, no battery, no antenna,
never the pedestal) and it comes out at once, no tape (`Now = true`); its discs
are written in the Noise Journal as it comes. Every 10 seconds the next one comes,
in the Journal's order, and the ones before it stay. Your `_G.Noise90` settings
carry over; S-90, XS-90 and A-404 kill you instead of kicking you out (`Kick = true`
to be kicked), or a kick would end them all. The TV is a little bigger
or smaller each time (`TVScale`). Every setting is at the top of the script
(`_G.Noise90 = { ... }`). The props come from `assets/noise/NoiseWorld.rbxm`,
the faces from `assets/noise/Wiki_*.png` (the wikis'; G-90's `Face_G90.png`, R-90's `Face_R90.png` and its spots `Speckle_R90.png`), the discs' art from
`assets/noise/Disc_*`, the journal's icon `Noise_Journal.png`, the tinted tape from
`assets/noise/NoiseFramesGray_*.jpg`.

Still to come: the troll laugh (any sound id in `Laugh`; A-90's sound sped up
without one). C-90 is on no wiki: it is the "contrary" one for now.

## 3rr0rbu2h (Errorbush)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/Errorbush"))()
```

Ambush, broken. It comes through like Ambush and keeps coming back, 5 to 10
rebounds. At every rebound it glitches into its other form, red and yellow or
blue: its face, its light, the colour of the rooms and the pitch of its scream
change with it. The scream is Ambush's own sound, distorted, chopped and
skipping; between two forms, a glitch and a burst of shards. A faint copy of its
other face jitters behind the one it has, and now and then flashes over it.

The crucifix stops it with DOORS' own ritual (the blue pentagram and its chains,
no colour of its own); it uses the crucifix you have. It is only this
loadstring: it is not in `MainScript`'s schedule or in `GradishDev`.

Its model is `Errorbush.rbxm`; its two faces are `assets/errorbush/Errorbush_Ember.png`
and `Errorbush_Azure.png`, downloaded once into the executor's folder (`Errorbush/`).
Until it is on `main`, the script takes them from the branch it is made on.

## Interminable Rooms

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/InterminableRooms"))()
```

opens the panel; with `_G.Entity = "A-60"` before it, that one comes at once, no panel.

**The panel**: every entity, one row each: its picture (its GIF moving), its name, what it
is ("runner · rebound · controlla nascondigli"). Drag it by its red title; search at the
top; click a row and it comes (14 can be about at once). Two tabs:

- **Spawn**: as in the game, it can kill you.
- **Senza danno**: it comes and does all it does (it runs, checks, screams, breaks the
  hiding places), but it cannot hurt you: no damage, no kick, no jumpscare, no theft;
  what it summons is harmless too.

The pictures are downloaded only for the rows in sight, a few at a time (then they are on
disk, at once the next time). While it is open DOORS gives you the mouse; hold the right
button to turn the camera. `-` or **P** folds it to its title and gives DOORS the mouse
back (P again opens it); `X` shuts it (what is about goes on).

Every page of the [Interminable Rooms wiki](https://r-interminable-rooms.fandom.com/wiki/Roblox_Interminable_Rooms_Wiki)'s
Entities category, events, scrapped and removed ones included: 675 entities (some pages hold
several: A-60's has X-60 and XX-60 too). One script, the name in `_G.Entity`.

Each one comes with what its page has:

- **its picture** on a billboard that faces you, standing on the floor, in its light's
  colour (rainbow ones cycle). 105 of them move: their GIF, made a sheet of frames. A-60,
  X-60, XX-60, A-100, U-60, V-60 and a few more switch between their faces, quickly, as in
  the game.
- **what it looks like on its page** ("Appearance"), on it: its glow; sparks; lightning
  (E-22, its light flashing); black smoke left behind (E-22, E-60, U-5); static around it
  and its picture glitching (A-60, A-120, V-50, U-300); ovals going round it (E-142,
  E-144); spinning (V-60, U-300); sound waves (V-35); twitching; huge (U-200, U-300,
  U-400) or small (U-5); no light at all (U-5, V-50). The fast runners leave after-images.
  217 pages say something of the kind.
- **its sounds**: spawn (heard everywhere), ambience on it (and its far ambience as you
  get away), jumpscare, despawn, scream, locker breaking, explosions, its lines. 664 have
  them: the in-game ones, not the "origin" files, the old or unused ones. The ones the
  wiki has no sound for take their family's (X-246 sounds like A-246) or their kind's.
- **what it does**, from its Behavior (or, where that says TBA, its Description), and for
  the best known ones what their page tells in full:

| Kind | How many | What |
|---|---|---|
| runners | 306 | from the lobby (the oldest room loaded) to your room; unhidden in its way, you die. Rebounds (A-35 once, X-35 twice, A-183 2 to 6, A-221 10 to 20, Scary Retro 10, A-219 100...), faster each time where it says so; A-120 and A-130 stop at the door each time, a little longer each time, and A-120 leaves an M-120 there (it shoots at you); idling (A-60 5 s), sinking (X-60, E-60), going on past you and back at you if you come out (A-332); from ahead (A-200, A-246: they come after you if they see you), a few rooms behind (A-245), your own room backwards (A-5, A-80: it flings you and takes half your health, E-144); A-183 and V-183 stop and scream when they see you, then change speed; in bursts (A-350), a room at a time with static (V-50), laggy (A-400); E-15 faster with every door you open; V-256's speed never the same, its bombs, then it fades and explodes; V-60 speeds up, idles, swells and pops; U-330 goes off and is suddenly back in your room, twice; U-380's clones rush back through; U-400 turns every light red; fake despawns with the rooms gone dark (V-35, E-200); V-15's messages across your screen ("EVIL IS COMING", "COMING IN HOT!"...) |
| checkers | (runners too) | at your room it goes to the hiding places one by one (`locker`: wardrobes, lockers, closets; `table`: beds, tables, desks): hidden in the one it checks, you die. A-150 climbs out of a paper in your room and goes back into it; A-160 checks the 6 rooms before yours too; E-333 lockers in your room, tables in the one before, lockers in the one before that; Billy-140 splits in two (lockers, tables); A-100, A-315 (only the hidden), LKR-175... |
| breakers | (runners too) | the hiding places it breaks can no longer be used (A-245, A-244, X-244, TABLE-244); V-100 and V-150 only lock them for a while |
| wanderers | 205 | around your room: the E-1 family (E-1 only hurts with your light on it, and goes when the bulb of its room bursts), the Boots and Tiny Timbs Tony (kick you away), Chasin Cleats Charles (charges), JOLLY-1 (your light makes baubles that hurt), Ew-1 (your light makes it cry, sometimes a Fish), M-120 and Baby Bully Billy (shoot), Nuclear bomb (explodes), Noah (only the hidden), Bully Billy's line |
| standing | 52 | in your room: A-258 (first its portal of sound waves, then it screams so loud nothing else can be heard), A-0 kicks you if you are too fast (the anticheat), A-404 and E-0.6 guard the door (E-0.6 blows you up), V-99 kills on touch, E-50 heals you (Take: 8 health), AN-42 grows and explodes |
| chasers, hoppers, lurkers | 55 | after you until you hide (Horror15, Bobertson); XV-5 latches on; Evil Bike sends you back a room; the Ah thieves take an item (you get it back next run); V-5 shakes, charges up and hops at you; BOMBER-5 hops leaving bombs; Fish and the Vifos hop about; the lurkers wait in a corner and lunge when you come close |
| with a way of their own | 13 | DG-1 digs into the floor and comes up under where you were; A-59 is here and gone all around what you look at, then comes for you; E-80 and XE-80: a tombstone drops on it, bounces, it gets angry (XE-80 throws it at you); E-125 is one of your lockers (red, glowing): hide in it and you are left with 1; ULB-278, TLAB-278, Purple and Sad Billy come out of a portal on the wall and break a locker or a bed (you inside: you die); V-79 speeds up, keeps going 7.9 s, stops and turns, seven times |
| on your screen | 10 | E-0 (one click), XE-0 (5-15), XXE-0 (10-100), MT-0 (it may clone), QT-0 (it bites), all of a random colour, Joklanna; Trollface-90: stop moving and do not turn |
| summoners | 12 | A-300 changes colour and the entity of that colour comes (A-15, A-35, A-60, A-100, A-200, A-245, Noah); X-300, XX-300, E-300, XE-300, V-86 (one of A-200, A-300, E-144), PH-1 (Tiny Timbs Tonys) |
| the rest | 22 | the Signardos are signs with their note; V-400 circles closer and closer, seen through walls, faster if you hide; V-247 drops from the ceiling (its sound is the cue); E-42 crosses your room from a wall (XE-42 again and again); XX-200 greys everything and says HIDE or DON'T HIDE |

And what you feel of them: the screen shakes all the way as one comes, the closer and the
faster the harder (harder still for the ones whose page says so; E-142's rumble grows);
the lights of the rooms it passes take its colour and flicker; the edges of your screen
take its colour, with static near the fast and the glitchy ones; the lights flicker when
a runner spawns. Caught: its jumpscare (its face all over the screen, its jumpscare
sound), then DOORS' death screen, "You died to A-60." with the wiki's tips. Damage is the
wiki's: instant death, a number, half your health (A-80), 1 left (E-125), or a kick out
of the game (U-80, U-120, S-10...; `Kick = false` kills instead).

The name as on the wiki (`"A-60"`, `"SCARY-60"`, `"Tiny Timbs Tony"`), any capitals,
with or without the dash (`"a60"`). Where the same name is on more pages, the game's
own is the plain one and the others have where they are from: `"X-100 (IF)"`
(Interminable Fever), `"E-69 (Scrapped)"`, `"V-160 (Upcoming)"`, `"XX-200 (IF)"`. A wrong
name prints the nearest ones in the console. Run it again for another: they can be about
together (14 at most). Outside DOORS it comes down a straight line at you.

```lua
_G.InterminableRooms = { Volume = 1, Delay = 2.5, Kick = true, MaxSpeed = 1000, PanelKey = "P" }
```

`Delay`: seconds between a runner's spawn sound and it setting off. `MaxSpeed`: studs a
second (A-221, Trollface and U-400 are faster on the wiki than anything can be seen).

What the wiki only says as "TBA" or "Unknown" (many scrapped and upcoming ones, the
P Shooters, the L- and lurker- pages) is a guess: its category (Runners, Wanderers,
Stationary...), else a runner if it kills, a wanderer if not.

The files are in `assets/ir/` (pictures `i_*.png`, GIF sheets `g_*.png`, sounds
`s_*.mp3`, mono, ambiences up to 45 s, the rest up to 15 s), downloaded the first time
an entity needs them into the executor's `InterminableRooms` folder.

<details><summary>All 675 names</summary>

A-0, A-100, X-100 (A-100), XX-100 (A-100), SCARY-100, A-120, SCARY-120, SCAMY-120, A-15, X-15, XX-15, SCARY-15 (A-15), A-150, SCARY-150, A-160, A-183, SCARY-183, A-200, SCARY-200, A-220, A-221, A-245, SCARY-245, A-246, A-247, A-258, A-260, A-278, A-29.3, A-300, SCARY-300, A-315, A-332, SCARY-332, A-35, X-35, XX-35, SCARY-35 (A-35), A-350, SCARY-350, A-377, A-404, A-5, A-50, A-60, X-60 (A-60), XX-60 (A-60), SCARY-60, X-60, XX-60, A-80, A-83, AN-19, AN-21, AN-42, AN-55, AN-64, AN-73, AN-99, AN-99 #2, AN-99 #3, AN-99 #4, ATTACK-1, B-11, C-9, B-33, C-15, L-46, R-183, P-831, Z-72, Xoah (Admin), B-60, Colored A-150, Colored A-278, Colored A-332, X-183 (Admin), X-332 (Admin), E-10 (Admin), XXX-35, A-45, A-105, CUTE!-10, ADORABLE!-0.9, Among Us E-1, Among Us DG-1, CUTE!-332, BIRD-332, Ah 100, Ah 221, Ah 246, Among Us B-140, Angry Billy, A-1 (April Fools), Ay eight ee, Ay two hundred and fifty eight, XX-100 (April Fools), A-260 (April Fools), A-400, Weegee A-35, Weegee X-35, Awesome-60, Mike Wazowski A-120, Pac-Man A-183, Awesome-200, Bille bobb, Blueh Bobb, Tabble Bobb, Beast Bendy A-350, Humanoid E-1, Humanoid XE-1, Humanoid XXE-1, Atrocious-258, BE-50, BIG BOOTS BOWEN, BIGGE-1, BLKR-175, BLUE BOOTS BOWEN, BM-1, BMEw-1, BOE, BOMBER-5, Baby Billy, Baby Bully Billy, Baby Jimmy, Baby Timmy, Bifo, Billy-140, Billy, A-0.666, A-M3, Boah, Bob (Original), Bob (April Fools), Bobertson, Bobumtsking, Bohn, Bombastic Boots Brooke, Bubugugup, Bully Billy, Bus, CATALYST-15, CATALYST-35, CHA-1, CHACHA-1, CHAEw-1, CHES-278, Car, Chasin Cleats Charles, Cube, CutE-1, DG-1, DNC-1, DRILL-1, Despawn Wall, Diggin Dockers Dean, Disruptor, Distresso, Dog, Drillin Derbies Daniel, E-0.6, E-0, E-1, E-10, E-111, E-120, E-125, E-140, E-142, SCARE-142, E-144, SCARE-144, E-15, E-175, E-2, E-200, SCARE-200, E-22, SCARE-22, E-246, E-333, E-35, E-42, SCARE-42, E-50, E-60, SCARE-60, E-69, E-80, E-95, EOWL-190, EOWL-95, EOWLET-190, EQU-278, ERM-120, Energetic Billy, Ermm there is an error, Evil Bike, Ew-1, Fish, Front A-200, G-01100111 01101100 01101001 01110100 01100011 01101000, G-3.1415926535996932384626433, Generic Blue Locker Checker Number 30, Generic Locker Checker Number 30, Generic Table Checker Number 30, Horror15, Horse, 3-60, A-1 (IF), A-130, A-219, A-244, A-248, A-59, SDA-15, A-113, A-170, CONSUMPTION-244, TINY-244, BOOM-244, GRAY-244, BLUEXTRA-244, GANDER-244, FIX-244, DUPLICATE-244, Evil Sneakers Bob, Tall Trickers Tyrone, ACIDCONE-1, ACIDCONE-2, PLASMACONE-1, W-3, XW-3, BKF-15, BLOODCONE-1, BLOODCONE-2, BLOODCONE-3, BLOODCONE-4, BLOODCONE-5, BLOODCONE-6, BLOODCONE-7, TEETHCONE, TEETHMINI, BLOODCONE-120, EVIL-244, BLUE-244, BLUECONE-1, BLUECONE-2, BLUECONE-3, BLUECONE-4, BLUEVIL-244, E-100 (IF), E-230 (IF), E-300 (IF), E-thief, EAT-15, LK-1, RVR-15, Ryan (IF), S-1, S-10, S-127, S-130 (IF), S-150 (IF), S-190 (IF), S-200, S-210, S-230 (IF), S-270 (IF), S-40 (IF), S-60, S-90 (IF), TABLE-244, TLAB-15, ULB-15, V-160 (IF), V-319 (IF), V-79, V-86 (IF), X-1, X-100 (IF), X-120 (IF), X-130, X-150 (IF), X-183 (IF), X-219, X-221, X-244, X-246, X-248, X-278, X-300, X-332 (IF), X-350, X-80, XBLUE-244, XE-100, XE-142, XE-144, XE-200, XE-230, XE-300, XE-42, XE-60 (IF), XE-69, XE-95, XM-120 (IF), XS-1, XS-10 (IF), XS-127, XS-130 (IF), XS-150, XS-190, XS-200, XS-210, XS-230, XS-270, XS-40, XS-60, XS-90, XTABLE-244, XTLAB-278, XV-200, XV-27 (IF), XV-35 (IF), XV-50 (IF), XV-60, XV-86, XX-100 (IF), XX-150, XX-200 (IF), XX-244, XX-258, XX-300, XXE-22 (IF), XXE-230, XXE-300, Xoah (IF), lurker-35 (IF), ?-100, JOLLY-1, Jackenstein, John 2, John, Joklanna, KEZU-278, Killer Kyle, LKR-175, Lurker-15, M-120, M-93.1, ME-50, MOQU-278, MT-0, Mario, Mason, MonsterE, Mr Sprinkles, Noah, Nuclear Nikes Nathan, Nuclear bomb, OWL-125, OWL-15, OWL-5, OWL-50, P-1, P-3, P-5, P-8, P-10, P-14, P-17, P-20, PH-1, Peter The Faster, Pickin Pumas Paul, PlEading-1, Prunsel, Purple Billy, Purple Fish, QT-0, REtro-42, REtro-60, RKOL-278, Radioactive Runners Remington, Rainbow-200, Red Scribble, Retro Rockets Robert, Romplians, S-0, S-49, SURVIVE BEAR FROM 2027, Sad Billy, SCARY-15 (Scary Mode), SCARY-35 (Scary Mode), Scary Retro, A-3, GHOST-5, LASER-5, S-40-ATR, S-40-MOU, S-40-OTL, V-150 (Scrapped), WINTER-20, X-3, BOUCBM-1, CHARGER-1, CHKR-1, FT-278, GN-1, SHOVEL-1, SKNY-278, pickaxe-1, stickofdynamite-1, A-264 (Scrapped), DIG-1 (Scrapped), CHARGE-1 (Scrapped), BOMB-1 (Scrapped), BE-245 (Scrapped), MOR-245, OXO-245, ZIBO-245, ATC-1, E-69 (Scrapped), E-146, E-148, BOMR-5 (Scrapped), XV-27 (Scrapped), XV-35 (Scrapped), XV-50 (Scrapped), A-1 (Rebuilt), A-135, A-231, A-264 (Scrapped) #2, Timmy, Blue Timmy, Miserable Timmy, A-1 (Scrapped), ALRT-190, BE-245 (Scrapped) #2, BOMB-1 (Scrapped) #2, BOUC-278, CHARGE-1 (Scrapped) #2, CHK-190, CHS-278, CIL-278, DIG-1 (Scrapped) #2, E-100 (Scrapped), E-125 (Scrapped), IB-278, Jordent, L-135, L-198, L-231, L-25, L-271, L-320, L-389, L-432, L-465, L-500, L-550, L-610, L-80, Le creatures, M-120-B, M-120-C, M-120-D, Pickaxe-1, RBND-190, Remi, Ryan (Scrapped), Stickofdynamite-1, T-120, T-190, T-270, T-330, T-50, TRP-190, V-331, X-100 (Scrapped), X-120 (Scrapped), X-150 (Scrapped), X-183 (Scrapped), XA-1, XM-120 (Scrapped), XS-130 (Scrapped), XXA-1, lurker-100, lurker-120-Minion, lurker-120, lurker-150, lurker-183, lurker-200, lurker-245, lurker-278, lurker-300, lurker-35 (Scrapped), lurker-60, Signardo 0, Signardo 10, Signardo 11, Signardo 12, Signardo 13, Signardo 14, Signardo 15, Signardo 16, Signardo 17, Signardo 18, Signardo 2, Signardo 3, Signardo 4, Signardo 5, Signardo 6, Signardo 7, Signardo 8, Signardo 9, Signardo, Signaretro, Signhia, Signopa, Slendersignardo, Spawn Wall, Stupid Eyeball, Stupid-1, T-0091., TBL-175, TLAB-278, Teleporter Signardo, The Creatures, The Dummies Behind The Lobby, Tiny Timbs Tony, Trollface-90, Trollface, Tropical Fish, Turnips, U-10 (April Fools), U-10 (Original), U-120, U-170, U-200, U-230, U-260, U-300, U-330, U-380, U-40 (April Fools), U-40 (Original), U-400, U-5, U-55, U-60, U-80, ULB-278, UNEVIL EROR, V-110, V-134 (Upcoming), V-160 (Upcoming), V-220, V-247 (Upcoming), V-264 (Upcoming), V-319 (Upcoming), V-383, S-150 (Upcoming), S-190 (Upcoming), S-230 (Upcoming), S-235 (Upcoming), Bob, BOMR-5 (Upcoming), E-230 (Upcoming), E-300 (Upcoming), E-387, GST-5, V-150 (Upcoming), Rob, Hob, LASR-5, S-130 (Upcoming), S-15, S-150 (Upcoming) #2, S-190 (Upcoming) #2, S-230 (Upcoming) #2, S-235 (Upcoming) #2, S-270 (Upcoming), S-40 (Upcoming), S-90 (Upcoming), V-134 (Upcoming) #2, V-160 (Upcoming) #2, V-247 (Upcoming) #2, V-264 (Upcoming) #2, V-500, V-86 (Upcoming), Upside Down Billy, Uselessvariant-258, V-100, V-120, V-15, V-183, V-200, V-256-A, V-256, V-27, SCARV-27, V-345, V-35, SCARV-35, V-400, V-463, V-5, V-50, SCARV-50, SCARV-5, V-60, V-99, VWM-345, Vifo, Vile-5, WigglE-1, X-160, X-200, X-220, X-247, X-258, X-260, X-315, X-5, X-83, XAN-19, XAN-21, XAN-42, XAN-55, XAN-64, XAN-73, XAN-99, XE-0.6, XE-0, XE-1, XE-125, XE-15, XE-2, XE-22, XE-246, XE-333, XE-35, XE-60, XE-80, XEw-1, XS-10, XV-15, XV-27, XV-35, XV-5, XV-50, XV-79, XVifo, XVile-5, XX-200, XXE-0, XXE-1, XXE-2, XXE-22, XXE-333, XXE-35, XXEw-1, XXV-5, XXVifo, XXcary Retro, Xackenstein, Xcary Retro, Xh 100, Xh 221, Xh 246, ZE-1, Zombie Pigman Brute, Zombie Pigman

</details>

## Surprises: ten one-shot entities

Ten scripts, each a single event that comes the moment it is run and leaves when it is done.
Only you see and hear them. Run one again and the one before goes (different ones can be
about together). Their sounds (`assets/surprise/`, made for them) and the kits they use
(HonchoSeek's, Noise 90's, Interminable Rooms' faces) are downloaded once into the
executor's folder. Outside DOORS the runners come along a line through you.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/HonchoRush"))()
```

(the same with `HonchoGiant`, `NoiseAmbush`, `SeekEyes`, `Listener`, `GlitchRush`, `Shadow`,
`TurnAround`, `Psst`, `EntityTrain`)

| Script | What it does | How to live |
|---|---|---|
| `HonchoRush` | The lights flicker and Honcho screams far away. He comes out of the floor in the oldest room loaded and runs to the newest (HonchoSeek's kit, Seek's run made his, his footsteps, a rumble), the lights of every room flickering as he passes, the screen shaking as he nears; then he sinks back into the floor | hide anywhere |
| `HonchoGiant` | "Something huge is coming." Honcho almost twice his size walks slowly to your room: every step a boom that shakes the screen, the lights of every room he enters shattering. In your room he stops and searches it for 6 s, then walks on and sinks | under a bed or a table (in a wardrobe or a locker he tears it open) |
| `NoiseAmbush` | Noise (Noise 90's kit, its hijacked walk) runs from the oldest room to the newest and back, 3 to 6 times, faster each time, a pause at each end; its static on your screen and in your ears, its scream when it is close | stay hidden until the static is gone for good |
| `SeekEyes` | Seek's eyes open one after another on the walls of your room and follow you. Looking at them fills a bar (whispers, your heartbeat); full, Seek's hands burst out of the floor around you: 35 damage. After 30 s they close one by one | don't look at them; hidden, they close |
| `Listener` | A new one: a tall blind thing of red flesh with a glowing ribcage, animated piece by piece (its walk with knees and long arms swinging, its head turning to sounds and twitching), comes in through the door and walks your room, clicking. It hears your steps: heard too much, it roars and charges, faster than you run, and kills. After a minute it leaves | crouch near it; hide when it roars (it sniffs your hiding place and goes) |
| `GlitchRush` | A black and purple mass of cubes with DOORS' Glitch texture, particles and sound runs through the rooms in jerks (skip, stop, skip), the screen going purple with cubes as it nears; at the end it glitches back and runs once more, then falls apart. Caught: 40 damage and your screen breaks into cubes | hide |
| `Shadow` | "Don't stop moving." A black copy of you does everything you did, 4 s later (2.5 s by the end). Stand still and it reaches you: your death. 45 s | keep moving; hidden, it loses you and starts again from where you come out |
| `TurnAround` | Everything blue and foggy, a cold hum. A glowing blue ghost floats at you from one end of your room; "TURN AROUND" and it comes from the other end. 7 times, faster each time. Touched: 40 damage | walk away from it, and turn when it says so |
| `Psst` | Your room goes dark. Three times a black head with white eyes and a ring of teeth comes out of the dark behind you or above you: "psst" | look at it within 2 s (it shrieks and flees); else it bites, 30 damage |
| `EntityTrain` | A-60's scream: A-60, A-15, A-35, A-100, A-200 and E-22 (their faces and sounds from `assets/ir/`) one right behind the other, like a train, through every room | hide until the last has gone |

Caught by one that kills: its face in yours (the camera on it, its sound), then DOORS' death
screen with its name and its tips.

## Hotel-: the Washroom and today's walk and sounds

For DOORS' **Hotel-** (place 110258689672367: today's DOORS calls it `BeforePlus` in its
`GetPlaceId`), from a dump of it compared with one of today's DOORS.

### The Washroom

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/Washroom"))()
```

Run it in room 0 (the lobby). Beside its door (0001), between the door and the pillar, the floor
opens: a railing round it, a `WASHROOM ↓` sign, and a staircase going down. You walk down it (no
teleport). The opening is only on your screen: the lobby's floor there is hidden for you and copies
of it are put round the opening (in room 0, as its own floor); the furniture on it or in front of it
(a chair, a plant) is taken away, whole, for you only. Where exactly: on the side of the door with
the least in the way (the room's walls and desks count much more than its furniture), measured
on the room as it is. Elsewhere it uses the room you are in.

- **The stairs**: in the Hotel's own style (its wallpaper `9754267662`, its wood floor, wall trim and
  ceiling colours from the dump), with the room's own lamps on their walls (copies of its
  `LightStand`, their stand against the wall as in its rooms).
- **DOORS' doors**: B-01 at the bottom of the stairs, B-02 at the far end of the laundry, B-03 at the
  far end of the attic, 0001 at the top of the way back: copies of room 0's own door (its leaf, knob,
  number plate, light, frame, its own `Open`, `Unlock`, `Error`, `Fall` sounds), shut as the Hotel-
  keeps them (`OriginalCFrameValue`), with none of its scripts, remotes or tags, but with its own
  mechanism: the leaf on its hinge (DOORS' `HingeConstraint` servo, its `BodyGyro`), the knob on its
  own servo. They open as you come: the servo swings the leaf away from you and the knob turns, as in
  DOORS (where nothing moves them, they swing the same way on their own). Each doorway is DOORS'
  (its frame on both sides, the wall 1 thick, the opening exactly as wide and tall as the frame).
- **The laundry** (past B-01): tiles below, the Hotel's wallpaper and trim above; the Hotel's pillars
  with DOORS' lamps on them, its beams with their carved brackets (room 0's `Rafter`); four of
  DOORS' windows high on the walls (room 0's: curtain, night sky, the rain on the glass and its sound,
  tagged `WindowLight` so that DOORS' own storm lights them up); two rows of washers back to back
  (some running a wash: the drum turning, water sloshing, the timer counting down), a bank of
  stacked steel dryers (now and then one starts with a bang and spins, its vent steaming), neon
  fixtures buzzing and blinking, pipes dripping, a flooded floor. DOORS' furniture from its
  `FurnitureTemplate`: shelves, the sideboard (folded linen and the typewriter on it), two dressers, a
  bookcase, the wall clock over B-02 (it shows the real time); room 0's luggage carts and paintings;
  folding tables, baskets, detergent, a wet floor sign, a sink.
- **The key of B-02**: B-02 has DOORS' own lock on it (its light red). DOORS' prompt on the lock
  (`Interact`, `Lock`, held a second): without its key `It's locked.` and the door's own `Error`. The
  drain valve is on one of three pipes (a different one each time). Turn it: the water gurgles down
  the drains, and in the big drain something shines: a brass key (its bow, its bit, a tag with
  "B-02"). Take it: it is an item in your inventory, in DOORS' hotbar (the Hotel-'s key icon), and you
  hold it as DOORS' items are held. At B-02 (in your hand or not) it goes from your hand into the
  lock's hole and turns, the lock opens (its own `Unlock`: its shackle swings up on its hinge, as the
  Hotel-'s fallen locks have it) and falls as DOORS' locks fall (body, hole and metal welded, the
  shackle on its `HingeConstraint`, let go), its `Fall` as it lands; the light turns green, the door
  opens, and the key is gone from your inventory.
- **The attic** (past B-02, up a few steps), after the reference photo, now big (56 by 84, 16 high):
  worn floorboards (loose ones, broken ones, two holes), dark wood wainscot and old boards, beams and
  a ridge, posts, four of DOORS' chandeliers, five of DOORS' windows, DOORS' fireplace burning (its
  armchair before it, the trim and beams stopping at its chimney). DOORS' furniture with drawers:
  three dressers (the `FurnitureTemplate`'s and room 0's) and three of room 0's tables with three
  drawers (a typewriter, desk lamps, a globe and the front desk's bell on them); four of DOORS' chests
  (`ReplicatedStorage.Chest_1`), five crates (straw in them), the sideboard with a painting over it
  (its globe and candles), a long table of old books, a bookcase by each door, DOORS' tall shelves,
  the lobby's key board, the grandfather clock (the pendulum swinging, ticking), DOORS' regal chair
  and couch, three of DOORS' wardrobes, a table with its chairs, luggage piled up and on a cart,
  barrels stacked, furniture under sheets, cobwebs, dust in the air.
- **The key of B-03**: B-03 is locked too. Its key is somewhere in the attic: in one of its drawers,
  crates or chests (a different one each time).
- **The way back**: through B-03 and up the stairs, the last door (0001) puts you back in room 0, in
  front of its door, and it all closes behind you (your items from down there too).
- **DOORS' own systems**: its location titles (`The Washroom`, `The Attic`, with a jingle), captions
  and tips; its prompts and their wording (`Open`/`Close` `Drawer`, `Collect` `Gold ( n )`,
  `Interact` `Lock`, `Inspect` `Painting`); its lamps flickering as DOORS flickers them
  (`flickerLights`); its lightning. **The Guiding Light** when you are stuck: its blue light and
  sparkles and its tip in blue (on the valve after 35 s; on the key; on B-02, DOORS' own `HelpLight`,
  once you have its key; on B-03's key after 45 s in the attic; on B-03; on the way out).
- **Hiding**: in the open dryers (DOORS' wardrobe animation and sound, a metal clank, the door shuts
  behind you, you see out through its grille), in DOORS' wardrobes (their own doors open and shut on
  DOORS' `Anim_EnterModel` and `Anim_ExitModel`, their own `SoundEnter` and `SoundExit`), under the
  tables (crouched). Always `Hiding` as DOORS knows it, DOORS' camera lock (`Bricks.CamLock`) and
  vignette. Stay as long as you like.
- **Things to find**: DOORS' drawers, each on its own rail (its `PrismaticConstraint` servo slides
  it out and in, as in DOORS; its own `Open` and `Close` sounds; what is in it lies on its floor and
  goes with it), four washers, the carts, the crates (their lid swings up), DOORS' chests (their lid
  and band swing up on their hinge): gold, the flashlight, B-03's key, or nothing. The flashlight is
  an item in DOORS' hotbar too (the Hotel-'s flashlight icon): it shines while you hold it (click:
  off, on).
- **DOORS' desk bell and paintings**: the front desk's bell rings with its own animation and sound
  (ring it too much and it says so, its `InteractSoundOverdone`); DOORS' paintings show their title
  when you inspect them.
- **No entities**: nothing comes for you down there and nothing hurts you.
- **Your steps splash**: while you are there the Hotel-'s `FootstepsClient.Slate` plays DOORS' water
  footsteps (the floor is Slate).

It is client-side (a script you run cannot make the server build a room): only you see it and walk
in it, and the gold and the items are only yours; your character's animations (hiding, interacting)
are seen by everyone, as they are DOORS' own. Run it again for a new one; `getgenv().__Washroom()`
takes it away (if you are down there, you are put back in room 0 first). Its textures and sounds are
in `assets/washroom/`, made for it.

### Today's walk and sounds

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/ModernHotel"))()
```

What is different between the two dumps:

| | Hotel- | today |
|---|---|---|
| walk (Forward) | 6502883750 | 17186586680 |
| crouch | 7715913939 | 105452559334645 |
| a door opening | 320946744 | 11447013731 |
| the hit when hurt / its ringing | 3802437361 / 1517024660 | 133527017562793 / 88790528744979 |
| footsteps | concrete (1), foil, brick | concrete (7), foil (4), brick; water, pavement, ground |

The Hotel-'s Movement still decides when and how much you walk or crouch; its old animations are
kept at no weight and today's take their weight every frame, at today's speed (your speed / 15),
starting a step on one foot or the other, at the old one's priority. Both places are LSPLASH's, so
today's animations should play as they are; if one cannot be loaded there, the Hotel-'s own is left
untouched (you never lose your walk). After 6 s the console (F9) says what it found: whether each
was loaded, what is playing on you, how many sounds it changed. Everyone's walk on your screen; every sound with an old id, now and later (each new
room's door). `getgenv().__ModernHotel()` puts it all back.

## MONOCHROME: VER

VER, the monster of **MONOCHROME** (Pt 2, place 134208374070897), in DOORS, with its creator's
permission. Taken from a saved copy of its place: the model of VER is in `Monochrome.rbxm` (VER as
its place has it: its skinned mesh and its 22 bones, its eyes, its two horns; nothing else of the
game).

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/Monochrome"))()
```

- **It comes out at the next door**: in the doorway of the room's exit, on your side, facing you (the
  next one along if that door is under 24 studs from you). The lamps around it go down (dim, not out:
  you still see the room), its joints crack, it twitches awake. It cannot kill you in its first 6 seconds, even standing next to it.
- **Its walk is its own**: its game has no animation assets for it. Its `MonsterGait` moves its bones
  itself (legs on IK, the step, the bob and lean, its arms, its head turning to you, breathing when it
  stands, walk blending into run, its bait pose, its grab, its strobe twitch), and so does this script
  (ported as it is, with its `MonsterAnimator`: how it follows where it goes, turns, steps; its horns on
  its head). So there is nothing to upload: animations uploaded to an account would not play in DOORS
  anyway (Roblox plays only the place owner's), these play anywhere.
- **What it does** (its game's AI ran on its server, which a saved place does not have; this follows
  its game and its briefing): it hears you move (crouch, or stand still); it sees you, less in the dark
  unless you hold a light; it walks slowly (5 to 6.5 studs a second), and runs when it sees you (a
  little slower than you: 1.5 under your speed, 10 to 13.5), or, from far, it freezes, silent, a
  bait, then bursts at you. Hide in a wardrobe if it spotted you and hope it throws it off: it comes to
  your wardrobe and stands there; it may find you, or just scare you. It cuts the lights now and then.
  Lose it and it searches, patrols, gives up and goes; get two rooms ahead of it and it comes back out
  at the next door.
- **Its sounds**: its double footsteps, its presence (louder the nearer, silent as a bait), its
  detonation, its hitches and joints, its grab's cracks and its strobe's static.
- **You feel it**: its game's camera shake from 20 studs (DOORS' camera too), its film grain, its grade.
- **Its kill**: its grab (crouched over you, the cracks, the strobe), its face filling your screen
  (its game's `MonsterKillCut`: every other sound silenced, its scream, the snap, black), DOORS'
  death screen: "You died to VER...", and its hints. Its phantom scares when it throws it off.
- **The radar**, in DOORS' hotbar (hold it) or on R: a real radar on your screen, bottom right. Its
  dial points the way you look (ahead is up), with rings at 25, 50 and 75 studs; its sweep goes round,
  and where it passes VER a blip lights up and fades, with a ping (higher the nearer) and its distance
  ("ABOVE"/"BELOW" on another floor); past 75 studs a mark on the rim shows which way it is.

Three more of it: set `_G.VER` before the loadstring.

```lua
_G.VER = "Noise" -- or "White", "Glitch"
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/Monochrome"))()
```

| `_G.VER` | What changes |
|---|---|
| (none) | VER as its game has it |
| `"White"` | white, black-eyed, a white glow on it; its blackouts are whiteouts (the lamps flare white); its grade greyer; its face on a white screen when it kills you |
| `"Glitch"` | made of DOORS' Glitch: its purple, its cube texture, its cubes coming off it, its pink light; its colours flicker; it skips a few studs ahead now and then (Glitch's sound); near you (16 studs), its cubes all over your screen; its face on Glitch's purple |
| `"Noise"` | it comes out of a TV, as Noise does: Noise's TV (out of Noise's kit, `MonochromeTV.rbxm`) hangs above the next door from the ceiling on its arm, static on its screen. **Hold its prompt** ("Play"): MONOCHROME's tape plays on it (its pictures and its sound, 25 s), the screen bursts, the lamps go down, and VER crawls out of the screen with **Noise's own Emerge** (from its kit, put on VER's bones: its body lying in the screen, crawling out, dropping to the floor, getting up), then wakes and walks with **its own walk** |



Its game's own sounds and images are used where they load. The ones its creator uploaded may be private
to its game: for those, stand-ins made for this (`assets/monochrome/`: its presence, its scream, a lamp's
click, the radar's ping, the film grain, its eyes) play instead. VER is black, made for its game's white
rooms: in DOORS' dark ones a pale edge goes round it, so it is seen. If its mesh will not load here (or
without `game:GetObjects`) it is made of its own bones (black limbs on them, our eyes if its own will not
load), and still comes out of the TV, walks, hunts and kills the same way, its face seen when it kills.
That is never needed when `VERBody.lua` loads: VER's own shape, taken from a saved copy of its place
(its body and its two horns as its game's physics hold them: 38 convex pieces, 1196 black wedges),
each piece on the bone it lies along, posed with its bones every frame: VER as it is, walking with its
own gait, crawling out of the TV with Noise's Emerge, and in its kill.
The console (F9) says what loaded: `[Monochrome] ... | its mesh: ok | its eyes: ok | ... tape: 24/24 sheets`.
Its creator's mesh may be loadable only in its own game: then only a copy of VER put on Roblox for
everyone (its model saved to Roblox and distributed on the Creator Store, by its creator) brings the
real VER into DOORS: `_G.VERModel = <its id>` before the loadstring loads it from there.
Its Noise tape plays picture by picture from its sheets (`Tape_01.jpg`...`Tape_24.jpg`, 15 a second) with
its sound (`Tape.mp3`); Noise's Emerge for VER is `assets/monochrome/Emerge.lua`.
`getgenv().__Monochrome()` takes it away; only you see it.

## Lucky Bottle and Unlucky Bottle

Two copies of DOORS' Starlight Bottle made of your two bottles (`Bottles.rbxm`): the green one (its cork, its
triangle, its sparkles) and the red one (its cap, the Mischievous Light's spiral). Each its own loadstring:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/LuckyBottle"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/claude/sei-qui-con-noi-ye4k62/UnluckyBottle"))()
```

**They need DOORS' Admin Panel** (the ADMIN PANEL pass, in your own hosted run): their luck is its commands,
sent as its own buttons send them. Without it there is no bottle, and DOORS' caption says why.

- **In your hand** as the Starlight Bottle: in DOORS' hotbar (its own icon), the Starlight Bottle's size and grip,
  its holding animation; click to drink it (its drinking animation, its sound). Drunk, it is gone, and it says
  nothing: what it did, you see.
- **The lucky one**: your health full, a star shield, a little speed (the panel's Apply Changes), and two of: +150
  gold, an item (a Crucifix, the Skeleton Key, lockpicks, vitamins, a lantern, a flashlight, a Starlight Jug,
  bandages, a Shakelight), God Mode for 20 s, the entities gone, the room lit, jumping and sliding, the dead revived,
  the next room, **the room all gold** (the room you are in: its parts gold and shining, Foil, its textures and lights
  gold; on your screen) **and 10000 gold** (the panel's Give Gold, 1000 at a time: its slider stops at 1000).
- **The unlucky one**: the wardrobes gone for good (for you: every one in the rooms, and in every room to come; the
  lockers too), you at 1 health, and two of: the lights broken, -100 gold, Rush, Ambush, Eyes, Screech on you, the
  Glitch on you, the lights flickering, **Creak** (from the panel, as its icon sends it) **with Noise's look**: as
  soon as it is here (any model or part named Creak, for 20 s), its parts turn to Noise's Neon and colour with
  DOORS' own static texture of Noise on every face, moving every frame as Noise's does, and Noise's outline; on your
  screen.

If the bottle's unions or the green one's triangle will not load in DOORS, a capsule of the same size and colours
and a triangle of ours take their place; without `game:GetObjects` the bottle is made here.

## Scanners (Object Scanner)

```lua
_G.Scanner = { Type = "Tablet", Variant = "Guiding", Color = "Lime" } -- all optional
loadstring(game:HttpGet("https://raw.githubusercontent.com/bonellocristian78-lab/Gradish-Mode/main/ObjectScanner"))()
```

One script, one scanner in your inventory: DOORS' two, the one you pick, each with
its own model and its own icon.

| `Type` | What it is | Only it has |
|---|---|---|
| `"Nokia"` (default) | DOORS' own scanner from the Mines: its model (`ObjectScanner.rbxm`), icon, sounds and animations | **SNAKE** (left / right click turn it) |
| `"Tablet"` | the NVCS tablet: the model of the tablet's own script (`rbxassetid://12594482248`), its icon, sounds and animations | **X-RAY**: the room seen through its screen, stars on what opens the way |

`Type`: `"Scanner"` (the Nokia, the default) or `"Tablet"`. `Variant`: `"Normal"`,
`"Guiding"` (Guiding Light: blue, its glow and sparkles) or `"Curious"` (Curious Light:
yellow). `Color` is its screen's colour, by name: `"Red"`, `"Orange"`, `"Yellow"`,
`"Lime"`, `"Green"`, `"Cyan"`, `"Blue"`, `"Purple"`, `"Pink"`, `"White"` (or any
`Color3`); by default its own, or the Light's. `FPS` is how many times a second its
screen is drawn (30, as DOORS').

Its icon is its own. In a Light, or with a `Color` of yours, it is the same icon with
its screen in that colour (the tablet: and the light its screen casts on its body; the
Nokia's red and green buttons stay as they are), and for a Light its glow and sparkles
around it. The script makes it once from `assets/scanner/Nokia.icon` or `Tablet.icon`
(their own icons without their background: `Nokia.png`, `Tablet.png`) and keeps it in
the executor's folder (`ObjectScanner/Icons/`).

A `.icon` file is `SCNICON2`, the width and the height (2 bytes each, big-endian), then
8 bytes a pixel, row by row: R, G, B, A, the Light's glow, its sparkles, their white
middles, and how much of the new colour the pixel takes.

In your hand (held on a Motor6D as DOORS holds its scanner):

| Key | What it does |
|---|---|
| Left click | on / off (in SNAKE: turn left) |
| Right click | inspect it: DOORS' own, turned round, brought to your face, tapped (in SNAKE: turn right) |
| F | the next function |
| L | a trick: tossed like a pancake, spun, shaken, smacked, juggled, nearly dropped (and once in a while it really falls) |
| X | drop it in front of you; **E** picks it up |

Its functions, on both: **SCANNER** (DOORS' own: a pulse every 2.5 s, a star on what is
worth finding 60 studs around), **ENTITIES** (what is coming, on a radar; it beeps
faster as it comes, and a "!" blinks on every other function), **EXIT** (an arrow to the
next door, its number, if it is locked), **HIDING** (where to hide, on a radar), **TRAPS**
(the Dupe's fake door, Snares, Giggles, Gloombat eggs; in a room with the Dupe, the real
door's number). Its battery never runs out; after a respawn you have it again (the one
on the floor too). Running it again replaces the one you have.

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

`UniversalAssets.obf` stays for the links that use it: it is the same obfuscated
script as `UniversalAssets` (see [Obfuscation](#obfuscation)).

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

## Obfuscation

The scripts people load are obfuscated with [Prometheus](https://github.com/wcrddn/Prometheus)
(Luau), with `tools/prometheus.config.lua`: the Medium preset's steps — strings
encrypted, names mangled, constants and numbers hidden, anti-tamper — without its VM
step (Vmify), which miscompiled our scripts at random (about one build in five) and
made them about 3.5 times slower. Their names, and so every loadstring, do not change.

The readable scripts are on the branch
[`sorgenti`](https://github.com/bonellocristian78-lab/Gradish-Mode/tree/sorgenti): change
them there, then bring the file over and obfuscate it, and run its tests on the result:

```sh
git checkout sorgenti -- Noise90
tools/obfuscate.sh /path/to/Prometheus Noise90
```

Prometheus needs one fix first (`git apply tools/prometheus-ifexpression.patch` in its
folder): without it, it cannot write Luau's `if ... then ... else` expressions. It does
not read Luau's types (`x: number`, `:: number`) or `//`, so the scripts do without them.

That includes the files made to be copied or filled in (`AchievementConfig`,
`AchievementTemplate`, `BadgeTemplate`, `ImagesA/...`): their readable versions are on
`sorgenti` too.

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
| `Noise90All` | every Noise 90, a new one every 10 s (fills the Noise Journal) |
| `InterminableRooms` | every entity of the Interminable Rooms wiki, `_G.Entity` |
| `HonchoRush` / `HonchoGiant` / `NoiseAmbush` / `SeekEyes` / `Listener` / `GlitchRush` / `Shadow` / `TurnAround` / `Psst` / `EntityTrain` | the ten surprises |
| `Washroom` / `ModernHotel` | the Hotel-'s custom room; today's walk and sounds in the Hotel- |
| `Errorbush` / `Errorbush.rbxm` | 3rr0rbu2h, the broken Ambush; its model |
| `ObjectScanner` / `ObjectScanner.rbxm` | The scanners (Nokia and Tablet, their Lights); DOORS' scanner's model, out of a saved place |
| `LuckyBottle` / `UnluckyBottle` / `Bottles.rbxm` | The two bottles (Starlight Bottle copies: luck through DOORS' Admin Panel, bad luck); your model of them |
| `Monochrome` / `Monochrome.rbxm` / `MonochromeTV.rbxm` | VER, the monster of MONOCHROME; its model, out of a saved copy of its place; Noise's TV on its arm (out of Noise's kit), for its Noise variant |
| `assets/errorbush/` | 3rr0rbu2h's two faces |
| `assets/noise/` | Noise's kit, tape and sheets; Noise 90's props kit, grey sheets and faces |
| `assets/ir/` | the Interminable Rooms entities' pictures, GIF sheets and sounds |
| `assets/washroom/` | the Washroom's textures (tiles, mould, grille, drum, stains, grate) and sounds (neon buzz, drip, gurgle, bang, clank, spin, valve, chime) |
| `assets/surprise/` | the surprises' sounds (steps, psst, bite, shriek, heartbeat, whispers, roar, clicks, hum, whoosh, rumble) |
| `assets/bottles/` | The bottles' hotbar icons and the green one's triangle |
| `assets/monochrome/` | VER's stand-ins, where its game's own files do not load (its presence, its scream, a lamp's click, the radar's ping, its eyes) and the film grain; its own shape (`VERBody.lua`); its Noise variant's tape (sheets, sound) and Noise's Emerge made VER's |
| `tools/` | Prometheus' settings for the obfuscation, the script that runs it, its fix for Luau |
| `assets/scanner/` | The scanners' own icons without their background (`.png`) and ready to be recoloured by the script (`.icon`) |
| `UniversalAssets` / `.obf` | the animator for DOORS' things and custom assets, readable and obfuscated |
| `GradishCheck` | the config report |
| `ImagesA/` | one file per entity saying where its picture comes from |
| `*.rbxm` | the models |
