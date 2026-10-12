# Changelog

## 2.28.1 — 2026-10-12

### Added
- **Idle habits.** A session that's done no longer just stands breathing until it sits down at 2 minutes. Every 11–19 seconds (each character has its own rhythm) it does something small for a second or two: looks back over its shoulder, shifts its weight from foot to foot, or handles its weapon. Sith and Jedi light their saber, spin it once and switch it off (Grievous spins all four, the Inquisitors give their ring a burst of rotor spin), the Gamorrean, Royal Guard, Tusken and Rancor swing their axe, pike, gaffi stick or claw up and back, gunners raise their blaster to eye level and blow the smoke off the barrel, and the Emperor lets lightning crackle in a raised hand. The unarmed ones bounce on the spot instead. Walkers, the pod racer, the speeder bike and the droideka keep to glancing and shuffling, since their guns are built in. Habits stop once it sits down, and never play while fighting, walking, thinking or waiting for you. In the app and the screen saver (`Sources/App/Habits.swift`). The existing quirks (Baylan's beard, Shin's practice, Cassian's glances…) carry on as before.
- **Signature moves** for four characters, in their idle rotation alongside the rest: **Darth Vader** puts a gloved hand to his chest panel and works the switches while its lights flicker; **Luke** spins his unlit hilt in his hand; a **stormtrooper** bumps his head on a door that isn't there, jolts back and rubs his helmet while stars circle it; **Boba Fett** swings his rangefinder down over his visor, its red light blinking. Each is drawn inside the character's own art (`Cast.signatureLength`, `Cast.signatureProgress`), so adding one is a case in `signatureLength` plus a few lines in its drawing function.
- **Fifteen more signature moves.** **R2-D2** plays Leia's message: a projector beam and a tiny scan-lined blue Leia in her white dress, flickering, a line slipping now and then, before it cuts out. **C-3PO** throws both arms straight up, hands flapping, rattling all over, mouth agape: we're doomed. **Han** spins his DL-44 twice round his trigger finger, drops it in the holster, and draws again (the gun is drawn once and rotated, `PixelCanvas.paste`). **Grogu** nibbles one of the blue cookies from Nevarro with both hands, bite by bite, crumbs falling. **Chewbacca** throws his head back and roars, arm up. **Obi-Wan** strokes his beard. **Yoda** leans on his gimer stick, ears drooping as he ponders and perking up again. The **tauntaun** shakes its head and snorts out a big frosty cloud. **Maz** twists her goggles and her eyes swim up huge behind them. **Grievous** has a coughing fit, hunched and jerking, puffs out of his mask. **Kylo Ren** has a tantrum and slashes at nothing. Light runs across **Captain Phasma**'s chrome (`drawGlint`). **Jabba** narrows his eyes and licks his lips. **IG-88**'s head bands dim while a bright light runs round them. The **Rancor** throws its jaws open and roars.
- **The Royal Guard doesn't fidget**: no glancing, no shuffling, no habits at all. It stands guard.

### Changed
- **No more title bar in the window: the place runs right up to the top.** The scene now extends under the header, which only draws the place's name and its two buttons over it, so you see 30 points more of every location. The bar is still there at 15% (85% see-through), and a shadow under the text keeps it readable on bright places (Hoth, Jakku); the screen-saver view keeps its solid bar, since it has its own place name and clock. The top strip still drags the window. This also retires the "dark band" centring (the title and buttons centred lower when the scene began with a dark band, and Endor's canopy, Theed, the Falcon and other dark places were mistaken for one, leaving them about 5 points low): with no bar there's nothing to match, so they simply centre in the strip.
- **Status Symbols moved to the top level of the menu**, right under Settings, so the key is one click away (right-click menu, menu bar helmet and the window's Crew menu).

### Fixed
- **Status Symbols shows its icons again.** On macOS 27 menus don't draw `NSMenuItem.image` at all (not even a plain SF Symbol), so every row was text only. Each row is now its own view, the icon in a fixed box beside the bold name and the explanation (`Legend.row`), which macOS draws as before.
- **Idle Claudes stop fighting.** Since 1.6.0 every armed Claude was paired off whatever it was doing, so two sessions that had both finished kept duelling for good, and a Claude in a fight never sat down or fell asleep, so the 2- and 5-minute idle cues never showed. Now only sessions that are working or thinking are paired. One that goes idle or waits for you steps out 5 seconds later (`OverlayController.fightLinger`), so a pause between tools doesn't send it walking in and out, then sits and sleeps on the usual schedule. Idle Claudes don't cheer either. Agents fight as long as they run. Han and Greedo still find each other first, but only when both are fighting. The screen saver pairs the same way (`SaverView.crew`).

### Docs
- **The README covers today's crew changes**: idle Claudes stop fighting and pass the time with habits and, for some, a signature move (R2's hologram, C-3PO's panic, Han's blaster spin, Grogu's cookie…), the Royal Guard doesn't fidget, and the window's place runs up under a see-through title bar that still drags the window.

Taught 81 characters what to do with their hands. Still working on mine.

## 2.28.0 — 2026-10-12

### Added
- **Settings → Monochrome Menu Bar Icon.** The menu bar helmet in one colour, as a template image macOS tints to match the menu bar (dark in light mode, light in dark mode, dimmed when the menu bar is), like the system's own icons. It's Vader's helmet with only its dark pixels kept: the face under it is cut out and the eyes left in. Off by default; the colour helmet is unchanged.
- **27 new characters: the cast goes from 54 to 81** (46 villains, 35 heroes).
  - **Dark side (5):** **Baylan Skoll** (*Ahsoka*: long grey hair and beard, a dark cloak, an orange saber; he strokes his beard when he isn't fighting), **Shin Hati** (*Ahsoka*: platinum hair with a braid, dark armour, an orange saber; now and then she lights it and runs through a few moves), an **ID9 seeker droid** (*Obi-Wan Kenobi*: a hovering black ball with one red eye and five dangling legs, sweeping the ground with a red scan; agent only, like the MSE-6), the **Grand Inquisitor** (*Obi-Wan Kenobi*: a Pau'an with the tall ridged skull and red face lines) and the **Second Sister** (Trilla Suduri: black helmet with a grey faceplate). The two Inquisitors carry double-bladed ring sabers and spin them like a rotor while they wait for you or stand guard.
  - **More dark side (3):** a **bantha** (huge, shaggy, spiral horns; it chews and swishes its tail; unarmed), **Bib Fortuna** (Jabba's pale Twi'lek majordomo, head-tails swaying, pointed grin; unarmed) and **Watto** (*Episode I*: hovering on a buzz of wings, a hand out to haggle; unarmed, and as a session he now and then says "No money, no parts, no deal!").
  - **And 14 more villains, most of them armed:** **Moff Gideon** (black uniform and cape, the Darksaber: a black blade with a white edge), a **death trooper**, a **scout trooper** on a speeder bike (it fires the bike's cannon), **Asajj Ventress** (twin red sabers), **Savage Opress** (horns, a double red saber), **Jango Fett** (jetpack, Westar pistol), **Bossk**, **Dengar** (bandaged head, long rifle), a **droideka** (rolls in as a wheel, unfolds, and keeps its shield up while it fights), **Captain Phasma** (chrome, a cape lined in red), **Director Krennic** (white uniform and cape), **Governor Tarkin** (unarmed; as a session he now and then says "You may fire when ready."), the **Fifth Brother** and **Reva** (the Inquisitors who appear in *Obi-Wan Kenobi*, spinning ring sabers like the other two).
  - **Light side (2):** **Cassian Andor** (*Andor*: navy jacket, stubble, a blaster pistol; keeps glancing over his shoulder) and **Bix Caleen** (*Andor*: dark curls, a work jacket and tool belt; unarmed, and now and then she lifts her comm to call in).
  - **More light side (3):** **Cobb Vanth** (*The Book of Boba Fett*: the marshal's duster, scarf and badge, smoke curling off his pistol), a **pit droid** (*Episodes I–III*: gangly, a flat dish of a head; now and then it folds itself up into a little package and springs back open; unarmed) and **Kuiil** (*The Mandalorian*: the Ugnaught riding his blurrg, a long rifle; as a session he now and then says "I have spoken.").
  - Homes: Baylan and Shin on Jakku, the ID9 at Obi-Wan's hut, the Grand Inquisitor in the Jundland Wastes, the Second Sister and Cassian on the Executor bridge (with K-2SO), Bix and the pit droid at the sandcrawler, the bantha, Watto and Cobb Vanth in the Jundland Wastes, Bib Fortuna in Jabba's palace, Kuiil on Jakku; Gideon, Bossk and Dengar on the Executor bridge, the death trooper, Krennic and Tarkin on the Death Star, the scout trooper on Endor, Ventress and Jango on Geonosis, Savage and the droideka in Theed, Phasma on the Supremacy, the Fifth Brother in the Jundland Wastes, Reva at the Lars homestead.

### Changed
- **Any character can have a callout now**, not just villains: R0-GR's "Roger roger!" and Jabba's "Ho ho ho!" moved to `Cast.callout`, joined by Watto, Tarkin and Kuiil. Hero blasters can fire from any height (`agentFire`'s `muzzleY`), for Kuiil's rifle up on the blurrg.
- `leaderCount` is now 46 and `companionCount` 35; the new cases are appended, so existing cast ids are unchanged. `StatusStore.agentOnly` is now the MSE-6 and the ID9.
- `docs/roster.png` re-rendered; README cast lists updated.
- **The hook binary is now `clawd-wars-hook`** (it was `vader-hook`, from the project's old name), so Codex's `/hooks` list says whose hooks they are. On first launch the app re-points the hooks it finds, old name included, at the new binary. Codex asks you to approve them once more.

### Fixed
- **The screen saver shows your sessions with Clawd Wars closed.** It used to put on the demo whenever the app wasn't running. The hooks keep writing `~/.claude/vader-status/state.json` either way, so the saver now reads it (`SaverFeed.fromHooks`) and shows the sessions running, updated every second. It's rougher than the app's feed: sessions without hooks don't show (the saver's sandbox can't scan processes), one that died without saying goodbye stays until its state times out, and there's no ticker. The demo plays only when no session is running at all.
- **A lone idle session gets the demo in the screen saver.** One character standing still all night isn't much to watch, so with just one session, idle and without agents, the saver puts on the demo instead. Once it gets busy or needs you, it's back. The app's window still shows it.
- **Codex sessions leave when you close them.** Codex's terminal now runs its turns in a background server (`codex app-server --managed-daemon`) that keeps running after you quit, and the hooks run under it, so a session was recorded on that server's process and never seemed to end. With the app open it was dropped anyway, but the screen saver kept it on stage. Two Codex sessions also overwrote each other, sharing that one process. The hook now records the Codex session running in the same folder instead (`ClaudeProcesses.codexSession`).
- **The screen saver no longer shows an empty place when no AI runs.** Since the stage went empty with nothing running, the saver drew the place with nobody in it; it brings on the demo crew again.

## 2.27.1 — 2026-10-12

### Added
- **Han shoots first.** When Han Solo and Greedo are both on stage, sessions or agents, they always face off. They're paired before any other fight, so everyone between them walks over to make room. Their shoot-out runs as usual until, at random, Greedo doesn't duck (first 8–25 s after they meet, then every 30–75 s). Han's bolt knocks him into a backward somersault and onto his back, legs kicking in the air, dizzy stars circling and smoke rising from his vest. His own shot goes off into the sky. He stays down for three seconds while Han lowers his blaster and says "Sorry about the mess.", then rolls back onto his feet, says something ("That hurt!", "Ow! Maclunkey…", "Han shot first!"…) and walks back to his spot. On the desktop and in the window (`GreedoShot`, `Sources/App/Greedo.swift`). The screen saver pairs them too, but the shot doesn't play there. `CLAWD_GREEDO_EVERY=<seconds>` sets the interval for testing.
- **Settings → Status Symbols:** a key to everything over a character's head and around the crew: working, thinking, needs you (the red “!”), idle, asleep (zZz), no live status (“?”), the yellow you're-here marker, outline colours per AI, label colours per project, the ⚠︎ banner and the red OFFLINE banner. Each row is drawn with the same code as the crew (`Legend`), so the key can't drift from what's on screen.
- **`./build.sh --no-install`** builds and launches the copy in `build/` without copying anything to /Applications or touching any AI's hooks. It quits a running Clawd Wars first, since only one runs at a time. It's for people who'd rather run what they compiled themselves than a prebuilt app; a `build/` copy never takes over hooks that still point at a working app.

### Fixed
- **It builds again with Swift 6.2 and 6.3.** Two pixel-art expressions went over the type checker's limit: the accent palette (`Accents.palette`, a list of hex literals piped through `.map`) and the corner bounds of a ship sprite in `Locations.swift` (`.pi` arithmetic and a tuple-returning closure). The second one also produced nine knock-on errors (`cannot infer contextual base`, key paths, `Float16 * Double`). Both now state their types (`as [Int]`, `let a: Double`, a typed closure). The art is unchanged.

### Docs
- **The README says what you need to build from source, and what to do when it fails.** A new "Building from source: what you need" section lists the requirements: macOS 13+, Swift 6.2+ from the Command Line Tools or Xcode, the macOS tools `build.sh` uses, no third-party dependencies. It gives the toolchains it was tested with and explains ad-hoc signing (no developer account needed; macOS forgets the Accessibility grant on every rebuild). It covers the common failures: no developer path, the Xcode licence, the wrong `xcode-select` toolchain, and the "unable to type-check this expression" error (a bug in the code, not your setup; only the first error counts). `llms.txt` has the same requirements, plus how to write art code that stays under the limit.
- **The README tells people who don't want a prebuilt app how to build it themselves**: Command Line Tools only (no Xcode), then `./build.sh --no-install`, including what happens to hooks connected from the `build/` copy.
- **The README's symbol table points to Settings → Status Symbols**, and calls the focus marker what it looks like (a bobbing yellow marker, not a ◆).
- **The README has a table of contents** after the intro, linking every section (and the new build-requirements section under Install).

## 2.27.0 — 2026-10-11

### Added
- **23 new characters: the cast goes from 30 to 54.** All drawn in code on the same Clawd body, each with a weapon, a home location and its own little habit.
  - **Dark side (9):** one of the **Emperor's Royal Guards** (crimson robe and helmet, a force pike; home: the throne room), **Sebulba** in his pod racer (two orange engines, hovering; its flame jet is his blaster), **Salacious Crumb** (cackling, unarmed), **General Grievous** (four arms, four sabers, two green and two blue), a **Tusken Raider** (gaffi stick; always angry, so when it isn't fighting it shakes the stick over its head and hops), **Cad Bane** (wide hat, red eyes, twin blasters), **Admiral Thrawn** (white uniform, blaster pistol), **Hammerhead** (the cantina's Ithorian, unarmed) and an **MSE-6 mouse droid**.
  - **Light side (15):** **Jar Jar Binks** (eyestalks, flapping ears, arms everywhere), **Lando Calrissian** (cape lined in gold), **Zorii Bliss**, **Bo-Katan Kryze** (Nite Owl helmet), **Maz Kanata** (her goggles focus now and then), **Wedge Antilles** (X-wing pilot), **L3-37** (fist up for droid rights), **Mon Mothma**, **Padmé Amidala** (as at Geonosis), **Admiral Ackbar** (his eyes swivel), **Grogu** (lifts a hand to the Force), **Babu Frik** (on a crate, loupe out, sparks flying), **the Mandalorian** (beskar, cape, the long Amban rifle), **K-2SO** and a **GNK power droid**.
  - Names that wouldn't fit a 16-character name tag are shortened: "Royal Guard", "Tusken Raider", "Salacious Crumb", "Admiral Thrawn".
- **Agent-only characters.** The MSE-6 is never given to a session, only to agents (`StatusStore.agentOnly`; session picks use `leaderCast`). It's in the Playground's agent list, after the heroes.

### Changed
- New cast members are appended to `Leader` and `Companion`, so everyone's existing characters keep their ids. `leaderCount` is now 24 and `companionCount` 30.
- `docs/roster.png` re-rendered with the whole cast; the README's cast lists and contributing notes updated. The newer sprites live in `Sources/App/Recruits.swift` (added to the screen saver's build and the `Tools/RenderDocs` command).

## 2.26.3 — 2026-10-11

### Changed
- **The screen saver puts on a show when Clawd Wars isn't running.** macOS starts a screen saver on idle time alone and gives it no way to decline, so with the app closed you used to get an empty location and a big "isn't running" card. Now a random crew of four to six fights there instead: light side against dark, one or two characters who call the place home among them (Luke at the Lars homestead, a Gamorrean Guard at Jabba's palace), up to two of them agents. Each wears a name tag; there are no cards, since there's no real status to show. Every 3 minutes it wipes to somewhere new with a new crew (`demoEvery`, `cast(for:)`). The clock and place name still swap corners every 10 minutes against burn-in, and a quiet line under the place name says Clawd Wars isn't running. The System Settings preview shows the show too, instead of the card. With the app running, and in the window's screen-saver view, nothing changes.

## 2.26.2 — 2026-10-11

### Changed
- **"Small Window (75%)" is now "Compact Window".** Same thing (the window at 75% of its full size, scene and cards included), a better name. The setting underneath (`windowSmall`) is unchanged, so the choice carries over.
- **The title bar's view button only hides and shows the session list.** It no longer steps on to the screen-saver view: that's in **Settings → Screen Saver View in Window** only. Pressed in the screen-saver view, the button goes back to the scene with the session list. The little screen icon is gone; the button shows arrows in (hide the list) or arrows out (show it, or leave the screen-saver view), with matching tooltips.

### Fixed
- **The window stays on the desktop when it changes size.** Keeping it on screen only checked top and bottom, so switching to the screen-saver view (960 wide) near the right edge ran the window off the desktop. Every resize the app makes (entering and leaving the screen-saver view, Compact Window, fitting the list to the sessions) now shrinks the window to the screen's usable area if it's bigger and moves it fully inside, clear of the menu bar and Dock (`ClawdWindow.onScreen`).

### Docs
- **README images match the current scenes.** `docs/locations.png` re-rendered (the Death Star viewport's planet curve, Dagobah's new X-wing, the bigger Lars homestead, the throne room's stars inside its window, solid AT-ATs on Hoth), and `docs/window-hoth.png` re-shot from a Playground run with the new view-button icon. The Screen saver section now opens with `docs/screensaver.png`: the Lars homestead at 1440 × 900 with five sessions, a duel, agents and one needing you.

## 2.26.1 — 2026-10-11

### Changed
- **The project you're in has a bigger name.** The Claude whose terminal or editor window is in front (the one with the bobbing marker) now has its name plate 15% larger, in the window, on the desktop, in the screen saver and in the window's screen-saver view. The app now tells the screen saver which session that is (`SaverFeed.Session.focused`, optional so an older feed file still reads).
- **Speech bubbles make way for names.** Names now keep their place, centred just above each head, and only move up for another name. Each "z z", "…", "?" or "!" bubble is placed after them: beside its Claude's head on the side away from its nearest neighbour, else the other side, else just above its own name, whichever first stays on screen and clear of every name and bubble. Its tail points back at its Claude.

### Fixed
- **Name plates no longer jump far above a head.** In the window and on the desktop, a name touching any speech bubble, its own or a neighbour's, moved up a whole row, so a sleeping Claude's name ended up high above it, past its "z z". Fixed by the bubble change above.
- **Name plates sit on the head they belong to, standing or sitting.** The window's labels used the hand-entered `headTop`, which puts the Tauntaun's below its horns and doesn't know a seated character sits 4 rows lower. Each character's top is now measured from its sprite, standing and sitting (`Cast.drawnTop`), shared with the screen saver.
- **In the screen saver, tags are kept off heads by the real outline.** Every character counted as a 28-pixel-wide box, much wider than most, so in a smaller view (the window's screen-saver view) a tag next to a tall neighbour was lifted right over it: R2's over the Tauntaun, Luke's over Dooku. Tags now clear each character's drawn outline column by column (`Cast.drawnProfile`).
- **The tops of a name's letters were cut off at some window widths.** A name is rendered to an image of whole pixels, rounded up, but shown in a layer of its exact fractional size; the nearest-neighbour filter then dropped a whole row of pixels. Text layers now sit on the pixel grid at exactly the image's size (`SpriteLayers.update`). Boxed text is also drawn into a rect a point wider than measured.
- **Resizing the window in the screen-saver view no longer says Clawd Wars isn't running.** The app's timers pause during a live resize, so the feed aged past 5 seconds and the view treated it as stale until the mouse let go. Fed directly by the app, it never counts the feed as stale.

## 2.26.0 — 2026-10-11

### Added
- **A Clawd Wars screen saver.** The window's location at full screen, with the crew fighting across its floor (the same pairing as the window: Claudes fight Claudes, agents fight agents). The top left names the place and counts sessions, agents and who needs you. A large clock in opening-crawl yellow sits top right. An event log crawls along the bottom ("Darth Vader finished 'fix the scrollbar' in clawd-wars", "Luke Skywalker joined Darth Vader: Review the diff").
  - **Name tags and cards.** Every Claude and agent wears a name tag (project for a Claude, character for an agent) a fixed 3 art pixels over the top of its own head, so characters of different heights carry them at different heights. The top is measured from each drawn sprite (`spriteTop`, within 14 px of the body's centre), because the hand-entered `headTop` puts the Tauntaun's tag on its horns, and a tag that would cover anyone's head moves up past it. Each session has a card floating a little above the crew, in the crew's order, each at its own height (from its session id, so it doesn't jump), with a dashed beam down to its name. A card shows the title, status, what it's doing, your last prompt and its agents. Colours match the window: the project's colour for the card frame, title, beam and tags; the status in its own colour (green working, blue thinking, red needs you, purple asleep, grey idle, amber no live status). A session that needs you pulses: **INCOMING TRANSMISSION** with the question it's asking. When the cards won't fit side by side they overlap by half and stack over two rows, each beam dropping straight down between the lower cards; narrower than that they lose the prompt line. Four layouts were mocked up and rendered with the same scenes before settling on this one.
  - **Every 10 minutes it moves.** A Star Wars wipe, alternating a hard edge sweeping left to right and a clock wipe sweeping round from twelve (1.2 s), takes it to the home of another character on screen. With only one, or everyone from the place it's in, it goes anywhere. The old picture is frozen into a masked layer over the new one, under the crew and cards. At the same moments, against burn-in, the clock and the place name swap corners, and the cards and name tags move up clear of where they were. Ten minutes later they go back, and so on. The clock starts when the screen saver starts.
  - **How it gets its data.** The screen saver runs sandboxed in macOS's screen saver host, one copy per display. It reads a single file, `~/Library/Application Support/Clawd Wars/screensaver.json`, which the running app writes about once a second while the saver is installed (`SaverFeed`, `OverlayController.publishSaverFeed`). There's no extra background service. If the file is more than 5 seconds old, Clawd Wars isn't running, and the saver shows the last location with a "Clawd Wars isn't running" panel. A sandbox probe on macOS 27 confirmed the saver can read that folder. Inside the sandbox the home folder points at its container, so the real one comes from `getpwuid`.
  - **Install and updates.** **Settings → Install Screen Saver…** copies the bundled `Clawd Wars.saver` into `~/Library/Screen Savers`, restarts the screen saver host and opens System Settings → Wallpaper (where screen savers are picked on macOS 15 and later; the Screen Saver pane before that). Opening the bundle and letting macOS install it was tried first: its "this user or everyone?" prompt put it in `/Library/Screen Savers`, where System Settings didn't list it and the app can't update it without an admin password. On launch, the app replaces a per-user copy whose code or sealed resources (`_CodeSignature/CodeResources`, so a new thumbnail counts) differ from its own, and restarts the screen saver host, which otherwise keeps the old code loaded. **Remove Screen Saver** deletes it and its feed file, asking for an admin password if a copy is installed for everyone. The Homebrew cask's `zap` removes both. Built by `build.sh` into `Contents/Resources/Clawd Wars.saver` (plain `swiftc -emit-library`, sharing the sprite and location code) and signed with the app.
  - **Its thumbnail** is the "CLAWD WARS" title card from 0:04 of the promo video (`Resources/SaverThumbnail.png`, as `thumbnail.png`, `thumbnail@2x.png` and a combined `thumbnail.tiff`). macOS 27 shows a generic blue swirl for every third-party screen saver under "Other" whatever the bundle carries (reported elsewhere as removed by Apple), so it's there for older systems.
- **The window can show the screen saver.** The title bar's view button now steps through three views: the scene with the session list, just the scene, and the screen saver itself (the app compiles `SaverView.swift` in and drives it at 15 fps, through live resizes too). Its icon shows what the next click does (arrows in, a little screen, arrows out), and so does its tooltip. **Settings → Screen Saver View in Window** does the same. The view is fed the app's own feed rather than the file, so it works without the screen saver installed and in the Playground. In the window it has no clock (the menu bar has one), the place name is 50% larger, and hovering a card shows it again 1.5× larger and complete, on a solid backing, over everything. It has its own window size (960 × 630, or 720 × 473 small; a resize is remembered), and leaving it puts back the size from before. Right-click opens the usual menu there too. Hover cards for characters are off while it shows, since the scene is hidden.
- **Random location in the window.** The Location menu has **Random (somewhere new every 10 minutes)** under Automatic: a new place, never the one before, at every ten minutes of the clock.
- **Star Wars wipes in the window.** Whenever the window's location changes (Random, Automatic following the first Claude, or a pick from the menu), the old place is frozen and wiped away over the new one, alternating the hard edge and the clock wipe, under the crew. `Wipe` in `Locations.swift` is shared with the screen saver.
- **An AT-AT walks by up close on Hoth.** Every 100 seconds a big, detailed AT-AT (panel seams, cockpit slit, chin and temple guns, jointed legs with knees and foot pads) takes 42 seconds to stride across the snowfield behind the crew, about two-thirds of the scene's height and always bigger than the marching ones (`nearATAT`).

### Changed
- **Hoth's distant AT-ATs are solid.** They were drawn see-through to look far away, which showed badly at screen saver size. Depth is now colour and size: the farthest are small and washed toward the snowy haze, the nearest bigger, darker and faster, drawn far to near.
- **The Lars homestead's dome and vaporators are 50% bigger** (the dome 42 × 14, its door 12 × 9, the vaporators 36 tall with thicker poles and rungs), in every view.
- **The Death Star corridor's viewport looks out on space.** The blue disc in it (a planet sized to the viewport's height) was wider than the viewport on tall scenes and spilled across the wall. It's now a planet's curve rising along the bottom edge, and a Star Destroyer (a wedge with a bridge tower and engine glow) drifting past right to left once a minute. Everything in the viewport is cut off at its frame, and the Star Destroyer and the TIE fighter pass behind its bars instead of over them (`deathStarViewport`, `deathStarBar`).
- **Dagobah's X-wing looks like an X-wing, and is 50% bigger.** It was a thin diagonal line with two sticks. Redrawn from reference pictures: the long tapered nose with its red stripes, the canopy and R2 behind it, the boxy rear with a round engine on the wing root, the striped S-foil and its laser cannon, the far wing and cannon in shadow, tilted 26° nose-up with its tail in the bog. Drawn as flat shapes, turned and filled pixel by pixel (`xWing`), so the tilt, depth and size are one number each.
- **Small Window (75%) is a set size.** It used to shrink or grow whatever size the window had by 75%. It now sets the window to the default size (760 × 620, the list fitting the sessions with Fit Window Height) or exactly 75% of it (570 × 465), keeping the top left corner; just the scene is header plus scene at that scale, and the screen-saver view 960 × 630 or 720 × 473. Resizing the window by hand turns it off: the window keeps its new size and everything is drawn at 100% again.
- **The window's view button is drawn by hand.** The SF Symbol for "expand" came out smaller than "collapse" and sat off-centre. All its icons, like the close button, are now the same size and centred on the bar.
- **`release.sh` keeps only the newest two GitHub releases.** After publishing it deletes every older release, keeping their git tags. Old zips were never downloaded (the Homebrew cask names only the latest), and the release before the latest stays as a quick rollback. Set by `KEEP_RELEASES=2` at the top of the script.

### Fixed
- **A crash when a title bar button's tooltip appeared.** The tooltips were registered with a bridged string as their owner, which AppKit doesn't keep alive. Once it was freed, resting on the close or view button long enough crashed in `NSToolTipManager displayToolTip:` (EXC_BAD_ACCESS). The header now owns its tooltips and answers for them (`NSViewToolTipOwner`).
- **The Death Star II throne room's stars stayed inside the round window.** They were scattered over the square around it, so its corners had stars on the wall. `PixelCanvas.stars` takes an optional `inside` test.
- **Automatic location now retints the cards and redraws the scene when it changes**, as picking a location did. Only the header followed before.

- Spent the better part of an hour giving macOS a screen saver thumbnail in three formats. It showed the blue swirl every time. The swirl is undefeated.

## 2.25.0 — 2026-10-11

### Added
- **Wave off an AI you don't use.** An AI that's installed but not connected (say Codex, which you have but don't use with Clawd Wars) kept a red "isn't connected" banner on screen forever. The banner now has a **×** in the window, and the menu has **Don't Remind Me About Codex** under its ⚠︎ item (the desktop banner can't be clicked). Either one stops the banner, the menu warning and the first-launch offer for that AI. Connecting it later from Settings takes it off the list, and removing an AI's hooks from Settings puts it on, since that's a clear "I don't want this". Kept in `ignoredHooks`.

### Changed
- **Hooks are only added to an AI you've connected.** `build.sh` ran `--install-hooks`, which connected every AI installed on the Mac on every build, whether or not you'd chosen to. It now runs the new `--update-hooks`, which refreshes only the AIs that already have Clawd Wars hooks (`HookInstaller.connected()`), and never creates a hook file for one that doesn't. New AIs are connected only when you say so: the first-launch offer, the ⚠︎ menu item, Settings, or an explicit `--install-hooks`. Reconnecting after a `brew upgrade` only puts back what was there before.
- **Clawd Wars opens in a window by default.** The window shows the most at a glance (cards with what every session is doing), so a first launch now opens it instead of putting the crew on the desktop. Anyone who already chose a mode keeps it: only an unset `windowMode` defaults to the window.
- **The window starts at the Small Window size (75%).** Like the window itself, it's what a first launch gets; turning it off in Settings is remembered.
- **The desktop crew starts at the Small size.** Switching to the desktop without ever picking a size now uses Small (0.67) instead of Medium, matching the size the window draws the crew at. A size picked in Settings is kept.

## 2.24.0 — 2026-10-11

### Added
- **Projects are named after their repo, with a pill saying where it lives.** A card's title is now the repo name from the project's git remote (`origin`, else the first remote): `git@github.com:rodclemen/clawd-wars.git` → `clawd-wars`, whatever the folder is called. A project without a remote, or that isn't a git repo, keeps its folder name. A new grey pill left of the character pill shows the host (**GitHub**, **GitLab**, **Bitbucket**, **Codeberg**, **Azure DevOps**, **SourceHut**, or the host name for anything else), or **Local** when there's no remote. Each host has its own pill colour: GitHub purple, GitLab orange, Bitbucket blue, Azure DevOps sky blue, Codeberg teal, SourceHut yellow, other hosts pink, Local grey. The remote is read from the repo's `.git/config` on disk, so it works offline. It's re-read every 5 seconds, so a project that gets a remote mid-session (`git remote add`, or publishing to GitHub) switches name and pill within seconds. Sessions started in a subfolder find the repo by walking up, and worktrees follow their `commondir` to the main repo's config. Remotes that are paths on disk (`/srv/repo.git`, `file://…`) count as local. New in `Sources/Shared/GitRemote.swift`. A project that switches from folder name to repo name gets a new colour once, since colours are remembered per name.

- **Double-click the menu bar helmet to hide or show Clawd Wars.** Hides the crew on the desktop, or the window in window mode, and a second double-click brings it back without taking focus from the app you're in. The menu has a matching **Hide Clawd Wars** / **Show Clawd Wars** item, and clicking the Dock icon or switching between desktop and window also shows it again. Hiding isn't remembered: Clawd Wars always shows when it launches. A single click still opens the menu at once. The second click of a double-click closes the menu again, and if it lands on the helmet within 0.6 s of the menu opening, Clawd Wars hides. The status item reports every click with a `clickCount` of 1, so the system's double-click detection can't be used. Its double-click time can also be set to seconds (1.8 s on the Mac this was built on), so a fixed window is used instead.

- **The window stops growing after three sessions; the rest scroll.** With "fit height" on, the window used to grow one card per session until it filled the screen. It now makes room for three cards plus the top 28 pt of the fourth (so it's clear there are more), and the list scrolls from there, with a scrollbar that's there whenever the list is longer than the window. Overlay scrollers only appeared while scrolling, so nothing said there were more. The scrollbar is themed and quiet: the track is the location's panel colour, so it reads as part of the list, and the knob is a thin, faint bar (`ThemedScroller`, 10 pt wide). The cards narrow to make room for it. `CardsView.height(showingCards:)`, `ClawdWindow.cardsShown`.
- **A card shows four agents; the rest fold behind a chevron.** One Claude with 29 agents used to make a single card over 1,000 pt tall, and since the three-session limit counted cards, the window grew to the full screen. A card now lists its first four agents, then a "› 25 more agents" row in the project's colour that unfolds them all ("⌄ Show fewer" folds them back). The tree's └ moves to that row. Unfolded cards aren't remembered across launches. The list is also capped by height, at about three plain cards plus a peek at a fourth (`CardsView.maxListHeight`), so an unfolded crowd scrolls instead of stretching the window. Hovering an agent in the scene now shows its hover card in the window too (sessions still only get one when the list is hidden, since their cards show everything), so folded agents' details are a hover away.
- **Sessions in the same project are grouped as a tree in the window.** Open three Claudes in one repo and their cards now sit together under one project header ("clawd-wars  GitHub · 3 sessions"), each card indented on a tree line (├ into each, └ into the last), in the project's colour. Grouping is by AI and project (repo name plus host), so it works however the sessions were started, from one terminal or several. The group sits where its first session would have been, and the per-AI sections stay as they were. In a tree the header names the project and its host, so the cards are titled with the character instead and drop their name and host pills. A project with a single session looks as before. New `--projects=a,b,a` Playground flag to give playground sessions projects, for checking this. `CardModel.Tree`.
- **Heroes leading a session now raise a hand, hop and sit like villains.** Hero sessions ignored `urgent`, `sitting` and the mode, so the "needs you" cue was missing for about half of all sessions. A waiting hero now holds the weapon up, an ignored one waves it and hops, and a long-idle one sits (except R2-D2, the Tauntaun, Leia and the Jawa, whose robes or bodies already reach the floor). New `FightRole.ready(urgent:)`, `Companion.canSit`, `PixelCanvas.baseY`.

### Fixed
- **Renaming a project's folder no longer leaves the card titled after its parent.** After a session's folder was renamed (e.g. to `~/Code/my-app`), the card showed `Code`, the parent folder. The name came from the `cwd` in the hook events, and the folder had been renamed while the session was open in it, so the old path no longer existed and the hooks reported the parent instead. The info lines were already right because they read the live process's working directory. `StatusStore.snapshot` now names a session after the live process's working directory whenever it knows the pid, and only falls back to the hook's `cwd` when it doesn't.

- **One session per process.** A Claude process can only run one session, but `/clear` starts a new session id in the same process, and the old one lingered as a second card. When a hook event arrives, any other session on the same pid (and process start time) is dropped with its agents, and the app's snapshot keeps only the newest per pid. This also cleared out 41 fake sessions a hook test during the audit had written into the live state file, all attributed to one running Claude.
- **`brew upgrade` no longer leaves every AI disconnected.** Homebrew runs the cask's `uninstall` script on upgrade too, so `--uninstall-hooks` stripped the hooks from every AI and the new app never offered to reconnect. `--uninstall-hooks` now leaves a marker (`~/.claude/vader-status/hooks-removed`) listing the AIs it disconnected, and the next normal launch quietly reconnects exactly those that are still installed. Removing hooks from the Settings menu writes no marker. Running `--uninstall-hooks` by hand and keeping the app means the next launch reconnects; the README's uninstall steps delete that folder, so following them fully is unaffected.
- **Connecting one AI can't block the others.** `~/.claude` wasn't created when missing, and the first-launch offer included Claude Code even when it wasn't installed, so a Codex-only user clicking Connect got an error and Codex never got hooked up. Claude Code is now only offered when installed, every AI installs (and uninstalls) on its own, and all errors are reported together (`HookInstaller.installAll` / `uninstallAll`, used by the menu, `--install-hooks` and `--uninstall-hooks`).
- **Settings files kept as symlinks stay symlinks.** Writing a hooked AI's settings replaced a symlinked `settings.json` (stow, chezmoi) with a plain file, cutting it loose from the dotfiles repo. Writes now go through the link. Keys are written sorted so rewrites are stable. A settings file with comments (JSONC, which Gemini CLI and Qwen Code accept) now gets a clear "has comments in it" error instead of a generic parse failure. The hook's path is single-quoted in the command, so paths with `$`, backticks or quotes work; the old double-quoted form is still recognised.
- **"Needs you" clears once you approve a tool.** No hook fires on approval, so an approved 10-minute build showed "waiting" until it decayed at 15 minutes. A waiting session now counts as working once its process has been busy for two CPU samples in a row (about 6 s) after the prompt went up.
- **Long subagent runs keep their session alive.** Subagent activity never refreshed the parent session, so a long run decayed it to idle and past 3 hours deleted it mid-run (it came back as a different character). Agent events now refresh the parent's timestamp without changing its state.
- **State file hardening.** The hook retries `flock` on EINTR and skips the update when it can't get the lock, instead of writing unlocked. One undecodable record no longer wipes every session: records decode one by one, and a fully unreadable file is copied to `state.json.corrupt` before starting fresh. Recycled pids no longer keep dead sessions alive (the process start time is stored and compared), pid-less records stop counting for character assignment after 30 minutes, and timestamps from the future (clock moved back) are clamped to now. `SubagentStop` without a type now removes the oldest agent, as the comment always said. Sessions without a stored character got a different one each launch (`hashValue` is randomised per run, and `abs(Int.min)` could trap); they now use a stable FNV-1a hash.
- **A failed process scan no longer hides every session.** If the `sysctl` scan failed, the list came back empty and every character vanished for 3 s. It retries once and otherwise keeps the previous list.
- **`codex -p <profile>` sessions show up.** `-p` was a global "one-shot" flag, but for Codex it means `--profile`. One-shot flags are now per AI, and subcommands (`update`, `doctor`, `mcp`…) only count as the first non-flag argument, so `claude "update the docs"` is still a session. A flag's value is skipped when looking for that first word, and editor background servers (`app-server`, `mcp-server`, `proto`) count anywhere on the command line. Without this, the VS Code ChatGPT extension's `codex -c features.code_mode_host=true app-server` processes showed up as Codex sessions, one per VS Code window.
- **Repo names: more of `.git/config` understood.** Quoted values, inline `;`/`#` comments and `url.<base>.insteadOf` aliases (from the repo and your global git config) are handled; a host pill no longer reads "gh". Only regular files are read, so a FIFO can't hang the app, and the cache forgets folders not seen for 10 minutes.
- **Unplugging a monitor no longer strands the desktop crew.** Nothing listened for display changes, so after unplugging the screen they stood on (or a resolution change) the crew stayed off-screen until Reset Position. They now move back onto a screen. With no screen at all (headless, or lid closed at login) the app no longer crashes on launch.
- **The window's header follows the location.** In Automatic location, the scene switched when the first session exited but the header kept the old place's name and tint (and the cards their tint) until a resize. A regression from the redraw-only-on-change work earlier in this release.
- **The window's crew no longer vanishes when the last session leaves while shrunk.** With no one left, the fit-to-width maths divided by minus infinity and set the zoom to 0, so departing characters and the Falcon disappeared instead of fading or flying off.
- **Click-to-jump in editors picks the right window.** The folder to reopen was cut from the path with a substring search (`/x/foobar/foo` matched inside `foobar`); it's now rebuilt from path components, and only used when a tab's title matched exactly. Exact title matches for every folder are tried before substring matches, which need at least 4 characters, and folder names containing " - " (like `- CODE -`) now match. The Accessibility prompt is shown once per launch, not on every click.
- **Notification clicks after a relaunch jump to the session.** The notification delegate was only set when one was posted, so clicking one left over from an earlier run did nothing.
- **The menu bar helmet has a white outline**, like the sprites. The black helmet nearly disappeared on a dark menu bar.
- **"No Claude sessions running." is readable in light mode.** It used the system's secondary label colour, which is dark grey in light mode, on the always-dark panel.
- **Small fight and scene fixes.** Wicket's spear no longer goes through the floor when he rests (shouldered at -75°, like the Gamorrean's axe). The Rancor's duel sparks and deflected bolts land on its claw, which pivots at the shoulder, not at the hand (`Fighter.pivot`, `Cast.weaponPivot`). Dagobah's fog drifts in from off-screen instead of popping in at the left edge. Saber flicker follows the frame's time instead of the clock, so `CLAWD_SHOT` and the doc renders are reproducible. Zero-size scenes are guarded against the three places that would trap.
- **`build.sh` and `release.sh` are stricter.** A release build now fails if there's no Developer ID identity or signing fails, instead of silently shipping ad-hoc without the hardened runtime. `--deep` (deprecated) is gone: the hook binary is signed on its own, without the app's Apple Events entitlement, then the app. A CHANGELOG with no `## X.Y.Z` heading stops the build with a message instead of silently. `release.sh` refuses to replace an existing tag or GitHub release unless given `--force`, and checks that HEAD is `origin/main`. The Apple Events usage string says clicking any character (hero or villain) jumps to that AI session's tab.

### Performance
- **A fifth of the CPU: from a steady ~18% of a core to ~3.5% in the window, and ~2.5% for the crew on the desktop (three sessions).** Memory was already small (~40 MB, flat over time, no leak) and is unchanged. Profiling with `sample` found these costs:
  - **The scene's background was redrawn every frame.** The location's static picture was scaled up to Retina size 10–30 times a second. It now lives in its own `RoomView` behind the scene, which only redraws when the window is resized or the location changes. AppKit keeps its pixels in between. The scene view draws only what moves.
  - **The card background blended two colours per speck.** About a thousand 2×2 specks, each with an `NSColor.blended(…)` call, made up half of `CardsView.draw`. The two colours are now computed once and the specks filled in two batches.
  - **The process scan made one system call per process on the Mac**, then read the command line of every process you own, every 3 seconds (~95 ms per scan). `ClaudeProcesses.running` now gets all of your processes in one `KERN_PROC_UID` call and remembers what each one is, by pid, start time and name. Arguments are only read for processes it hasn't seen before. The working directory is still read fresh each scan, so folder renames still show.
  - **Frames were built even when nothing could be seen.** Frames and card updates now stop while Clawd Wars is hidden (double-click on the helmet) or its window or desktop crew is completely covered or minimised.
  - **Cards and header were redrawn on every status refresh**, twice a second, even when nothing on them had changed. The cards now compare what they show (`CardModel.signature`) and only redraw on a change, which in practice means once a second for the timers. The header has nothing live on it, so it only redraws when the location or its buttons change.
  - **The scene is drawn on the GPU.** Every frame, each sprite, label and the location's animated layer was scaled up 4× on the CPU (2× pixel art on a 2× Retina screen) and redrawn into the view. Now `SpriteLayers` (new, `Sources/App/SpriteLayers.swift`) shows a frame's `DrawItem`s as a reused set of Core Animation layers. Images become layer contents with nearest-neighbour filtering, so the pixel art stays sharp. Text labels are rendered once per look and cached. Mirroring and fading are layer transforms and opacity. The window's scene and the desktop crew both use it. In the window, CPU dropped from ~6.2% to ~3.5%. WindowServer, which composites the layers, was measured at the same load with either renderer (about 5–6 points over having no Clawd Wars window), so the work didn't just move there. `CLAWD_SHOT` captures views by drawing them, so with it set the scene still draws the old way.
  - **Timers show seconds only for the first minute.** After that they show whole minutes: `WORKING · 3m`, `ASLEEP · 22m`, `up 2h 4m` (was `3m 12s`). A ticking second counter made each card redraw every second. Now a quiet session's card redraws about once a minute. The hover cards on the desktop use the same format.
  - **An environment variable was read every frame.** `CLAWD_HOVER`, a debug switch, is now read once at launch.
- **Animation runs at 15 fps instead of 30 while something moves, and 7.5 fps instead of 10 when idle.** Measured at about 3 points of CPU less than 20 fps. The pixel art doesn't need more, and all animation is time-based, so nothing moves slower, only in slightly bigger steps. Dragging the crew is drawn at 15 fps too.

- **Nothing slow on the main thread every refresh.** The process scan and each process's CPU time now run on a background queue (the first scan at launch is still done straight away, so the crew is there from the first frame). The state file was read and decoded twice per 0.5 s refresh, once just to check it was readable; now once. Repo names are re-read from disk in the background, serving the cached value meanwhile. Accessibility queries time out after 0.25 s instead of the default ~6 s, so a hung editor can't freeze the animation, and the Terminal/iTerm AppleScript for click-to-jump runs off the main thread.
- **The desktop crew stops drawing while the screen is locked or the displays sleep.** Since the switch to Core Animation layers the desktop panel always counted as visible, so it drew 15 frames a second all night.
- **Fading labels are cached.** A label's fade was baked into its text colour, so every frame of a fade-in or fade-out was a new text image (and the text faded twice as fast as its box). Text is now built opaque and faded as a whole. The text-image cache is also capped at 16 MB, since hover cards are big. Wrapped label lines are cached instead of re-measured every frame.
- **Less work per frame in the scene.** Seven locations have no animated layer; they no longer get a blank full-scene canvas and image every frame, and the others reuse one canvas. The sprite outline pass checks its four neighbours without building an array per pixel. Characters still queued to walk in aren't drawn and thrown away, and fight effects don't allocate a canvas between duel clashes.

### Docs
- **README and `llms.txt` describe the new card titles, the host pill and the menu bar helmet.** The README's window section says cards are titled with the repo name (the folder name when there's no remote) and shows where the repo lives. The menu bar bullet lists Hide/Show Clawd Wars. `llms.txt` adds `Sources/Shared/GitRemote.swift` to the code map, notes that project names come from the live process cwd, and that the helmet opens the menu on click and hides or shows the app on double-click.

- **Docs match the code.** The README says the window grows to three sessions and scrolls past that. `llms.txt` lists all five AIs as hook sources and says `--install-hooks` connects every installed AI. The README says Terminal and iTerm2 jumps ask for Automation permission (Accessibility is only for editors). `Tools/MakeIcon`'s compile line includes `Locations.swift` and `Cantina.swift`, without which it didn't build.
- **Dead code removed:** `Scenes.torches`, the unused `flip:` option on `PixelCanvas.pattern`, and two cantina instruments that were never played.
- Learned that a menu bar icon reports every click as a first click. Double-clicks are a social construct.

- Audited the whole app, then filled the window with 41 Claudes testing the hook. The audit found that too.

## 2.23.1 — 2026-10-11

### Fixed
- **`build.sh` installs to `/Applications`, not `~/Applications`.** The user-level folder was the wrong home: with the app moved to `/Applications`, every Claude Code hook in `~/.claude/settings.json` still pointed at `~/Applications/Clawd Wars.app/Contents/MacOS/vader-hook` and failed with "No such file or directory", so no live status came through. `build.sh` now installs to `/Applications/Clawd Wars.app`, removes any leftover `~/Applications/Clawd Wars.app` or `VaderClaude.app`, and re-points the hooks at the new path. README (from-source and uninstall instructions) and `llms.txt` updated to match.
- **Moving the app no longer breaks the hooks.** Hooks store the hook binary's absolute path, but `HookInstaller.isInstalled` only looked for the `vader-hook` marker, so after a move it called the broken hooks "installed" and never fixed them. On launch the app now checks every registered hook (Claude Code, Codex, Qwen Code, Gemini CLI, Copilot CLI). If a hook's binary no longer exists, the app re-points it at its own copy (`HookInstaller.repairMoved`). Only a *missing* binary counts as stale, so a dev build run from `build/` never takes over hooks that still work. Tested by pointing all 12 Claude Code hooks at the old `~/Applications` path and relaunching: all 12 came back to `/Applications`, nothing else in `settings.json` changed, and Codex's working hooks were left alone. A re-pointed Codex hook needs approving again with `/hooks`.

### Docs
- **README brought up to date with the hooks.** `./build.sh` is described as connecting every supported AI it finds (it always did, not just Claude Code), and `--no-hooks` as leaving every AI's settings alone. How it works now says the hooks point at the app by full path and are re-pointed after a move. Uninstall names the per-AI **Settings → Remove … Hooks** items that actually exist (there's no single "Remove Claude Code Hooks" for everything) and adds `ClawdWars --uninstall-hooks`, which removes them all from the terminal.

- Spent a session discovering the Mac has two Applications folders and that the app lived in the wrong one. The hooks knew where it used to be.

## 2.23.0 — 2026-10-11

### Changed
- **Card headers are just the project**, bold in its colour. The character's name moves into a small pill on the right, under the status pill, tinted with the character's main colour: Yoda green, Vader black, Maul red, Rey sand. That colour is measured from the sprite's pixels (the most common colour, leaving out the shared Clawd body and the eyes) and cached per character. The text is lightened to stay readable, and very dark costumes are lifted a little so the pill still shows; and the text beside it stops short of it. The AI isn't repeated either: with several AIs running, the section header above says which AI it is. A card without a project keeps the character as its title.

### Fixed
- **A project's colour no longer flips when several sessions share it.** With three sessions in the same project (e.g. two Claude Code sessions and one in Claude Desktop), its accent flipped between two colours every half second, on cards, borders and labels. To decide whether a remembered colour clashed with another project, `Accents.update` counted every session with that colour, so the project clashed with itself and was re-coloured on every refresh. Projects are now deduplicated first. Found by capturing the real window four times a second and diffing the frames.

### Changed
- **No more flickering "you're here" border.** The card of the session you're in used to get a thick yellow border that switched on and off whenever the once-a-second focus check briefly got a different answer. Now:
  - every card keeps a steady thin border in its project colour;
  - project names stay steady too. The purple ↔ yellow "blink" some saw was never a feature: it was the accent bug fixed above;
  - the focus check is sticky: a new answer has to come back twice in a row before the focus moves, so a one-off miss no longer flips it (this also steadies the desktop's focus marker).

### Added
- **Settings → Small Window (75%).** In window mode, the title bar and the scene with its characters are drawn 25% smaller. Turning it on shrinks the window by the same factor, keeping its top-left corner; turning it off grows it back.
  - The session list keeps **normal-size text** and gets compact instead:
    - no project path;
    - one line of conversation: the reply once it's done, otherwise your last prompt;
    - portraits at 1.5× instead of 2× (they can now scale in half steps).
  - The title bar and scene keep their normal logical size in their bounds and are shown in a frame 0.75 times as big, so nothing inside needed new numbers.
  - The stage the crew is laid out on reports its logical size, and mouse positions are mapped back (`ClawdWindow.toStage`), so hover cards and click-to-jump still hit the right character.
  - The setting is remembered (`windowSmall`). Fit Window Height, the collapsed scene-only view and the screen-edge clamp all work at the smaller size.

## 2.22.0 — 2026-10-11

### Docs
- **README images re-rendered to match the app.** `locations.png` shows all the redrawn locations. `window-cantina.png` and `window-hoth.png` show the new title bar, the per-AI sections (Claude Code, Codex, Gemini CLI, Copilot CLI) with their outline colours, the agent tree and AGENT tags. `roster.png` and `social-preview.png` are refreshed.
- New `docs/shootout.png`: four frames of a Boba Fett vs Han Solo shoot-out (shield, duck, bolts colliding, armour ricochet).
- The README text covers the shoot-outs, agents shown as a tree, per-AI sections, and what each redrawn location shows.
- Playground: `--ais=` also gives each session a sample model name that fits its AI, so screenshots don't show a Claude model on a Codex card.

### Changed
- **The Rancor Pit redrawn from Return of the Jedi.** It used to be a flat speckled wall with a thin light cone and evenly spaced bones. Now:
  - a craggy cave: jagged rock faces with lit edges and cracks, stalactites along the top, and dark sides closing in;
  - the **trapdoor grate** in the ceiling, pouring a strong shaft of light (the bars' shadows in it, dust drifting), with Jabba's court bobbing as they peer over the edge;
  - the **heavy portcullis** half raised in an arch of fitted stones, with spiked bars and its chain, and the keepers' barred window lit from inside;
  - **bone piles** heaped in both corners (skulls, ribcages, long bones), one big skull, and the femur Luke jammed in its jaws lying on the floor;
  - damp puddles and water dripping from the ceiling.
- **The Battle of Hoth gets AT-ATs marching on the horizon.** Three distant walkers at different distances (one nearer and twice the size) march slowly toward the Rebel trench. Their legs step out of phase, their bodies rise and fall, and now and then a faint red bolt fires from a head. They're faded toward the colour of the snowy haze, the farthest almost sky-coloured, so they read as far away and never compete with the characters. A pair of snowspeeders also streaks across the sky every so often.
- **The Forest Moon of Endor redrawn from Return of the Jedi.** It used to be a row of evenly spaced identical trunks, each with the same little hut. Now:
  - depth: pale misty trees far back, grooved red redwoods in the middle, huge dark trunks framing the foreground, and sunbeams slanting through the canopy;
  - the **Ewok village**: thatched cone huts on platforms at different heights, linked by sagging rope bridges, with lanterns;
  - the **Imperial bunker** of the shield generator: a grey blast door with its panel light, set into a mossy mound;
  - a **scout trooper's speeder bike** crashed against a redwood, smoking;
  - arching ferns, flared roots and a fallen log on the forest floor;
  - animated: dust floating in the sunbeams, leaves drifting down, and the lanterns flickering.
- **Jakku overhauled as the Graveyard of Giants (The Force Awakens).** It used to be a small grey slab on flat dunes. Now:
  - a **HUGE crashed Star Destroyer** spans the whole scene: its nose is buried in the sand on the far left, and the hull rises along a tilted deck to the stern on the right, with the stepped superstructure, the bridge tower and its shield domes, and three engine bells on the stern face. It's hazy with distance, and sand is heaped against it.
  - **BB-8 rolls** back and forth across the sand, its orange rings turning and its head bobbing;
  - Rey's salvaged speeder (big intake, tarp-wrapped salvage and net) sits in the foreground, and a crashed TIE wing sticks out of the sand past the stern;
  - a white-hot sun with glare, heat shimmer over the dunes, and grit blowing across the ground.
- **The Millennium Falcon redrawn as its main hold from A New Hope.** It used to be a flat grid of identical grey panels. Now:
  - the hull curves overhead at both ends, with ribs along it;
  - the walls are crowded with pipes and clamps, blinking light panels, vents, red valve wheels and looping hoses;
  - the **dejarik table** with its curved cream padded bench, and two holo monsters hopping on the board;
  - **Luke's training remote** bobbing above the bench, firing a tiny red zap now and then;
  - a **big round hatch** (most of the wall's height) looking down the narrowing corridor into the cockpit: a wide window with **hyperspace streaking** out from its centre, the two pilot seats in silhouette, and the lit console;
  - deck plates with a softly lit strip.
- **Dagobah redrawn from The Empire Strikes Back.** It used to be a row of identical straight trunks. Now:
  - layered murk: pale misty trees far back, dark twisted trunks with hanging vines in front;
  - the gnarled tree over the **dark side cave**: twisted trunk strands, roots arching over the black cave mouth, branches dripping moss;
  - **Luke's X-wing sinking nose-up in the bog**, drawn large (1.7× its first size, so it reads as a crashed fighter, not a stick): thick fuselage, red stripes, canopy, an S-foil with its cannon sticking up and another going under, the engine glowing, and a reflection on the water;
  - Yoda's mud hut with a glowing round window, a lit doorway and a chimney;
  - animated: drifting fog, fireflies blinking, bubbles rising in the bog, and every so often a pair of yellow eyes surfacing in the water.
- **The Jawa Sandcrawler is now a junk hold.** It used to be a tidy row of droids for sale. Now:
  - heaps of scavenged junk are packed solid at both ends and piled lower along the back: broken R2 domes, gold protocol-droid heads (one eye still lit), GONK power droids, mouse droids, bent arms, wheels, pipes, crates and scrap plates;
  - cables sag from the ceiling, and a magnet crane holds a dangling R2 unit;
  - the rusty hull has ribs and rust streaks, and bolts and scraps litter the floor grating;
  - animated: flickering work lights, two pairs of Jawa eyes blinking in a dark doorway, and sparks spitting from a broken droid on the right pile.
  - The parts come from one `drawJunkPart` routine with a fixed seed, so each pile looks the same every time.
- **Obi-Wan's Hut redrawn as the inside of his domed hut from A New Hope.** The old version was a flat sand-coloured wall with a window and a shelf. Now:
  - a plaster dome curves overhead, with rough Jundland rock in the corners;
  - desert sun beams through the round window, with dust drifting in the light;
  - **Leia's hologram**, "Help me, Obi-Wan Kenobi": a flickering blue figure with her side buns, glitching now and then, above a projector on a low table and a round woven rug;
  - the chest that held Anakin's lightsaber, lid open, the hilt glinting inside;
  - his hooded robe on a peg and a curved sleeping nook with cushions.
  - The projector sits left of centre so the crew, who stand in the middle, don't block it.
- **Jabba's Palace redrawn to look like the Return of the Jedi throne room.** The old version was a generic brown wall with black arches and could have been any dungeon. Now:
  - smoky amber sandstone with a back ledge, softly lit rounded alcoves, and dusty light shafts falling from vents high in the wall;
  - **Han Solo frozen in carbonite** on the wall (raised hands, face relief, the little control lights);
  - Jabba's two-tier curved dais with red and gold cushions and the hookah, its hose curling back toward the throne and smoke drifting up;
  - the round trapdoor grate over the rancor pit in front of the dais;
  - hanging braziers that flicker, replacing the generic torches;
  - the Max Rebo Band stays on the right.

### Added
- **Blaster shoot-outs have saves now.** When two blaster characters fight (Han vs Boba Fett, Leia vs a stormtrooper…), most bolts no longer just land. Each shot plays one move from a fixed cycle, so the show varies without random flicker, and both shooters run through it out of step:
  - **Hit:** still in the mix now and then.
  - **Duck:** the target squats as the bolt arrives, and it whizzes over their head and fizzles out behind them.
  - **Collide:** the target fires back at the same instant, and the two bolts meet mid-air in a growing starburst.
  - **Shield:** a flickering blue bubble flashes around the target, and the bolt splashes on it.
  - **Ricochet:** armoured characters (Boba Fett, stormtroopers, R0-GR, IG-88, the AT-ST and AT-AT) take it on the armour with a "tink" of sparks, and the bolt glances off into the sky. Unarmoured characters duck instead.
  - The outcome comes from `boltOutcome(t:offset:defenderArmoured:)`, which both the effects layer and the sprite renderer use, so a duck in the sprite always matches the bolt flying over it.

## 2.21.0 — 2026-10-10

### Added
- **Promo trailer.** `promo/clawd-wars-promo.mp4` is a 45-second 1080p trailer, with its storyboard alongside. The README opens with it as an inline player: a 9 MB 720p copy uploaded to GitHub, since free accounts play videos only up to 10 MB in a README. Its first frame is the closing title card, because GitHub's player can't take a poster image and shows frame 0, which was black. A link to the full 1080p file sits under it.
  - Earlier in-progress versions had been swept into nine commits by `git add -A` while the video was being made in the same folder. That put about 150 MB of video in history. History was rewritten with `git filter-repo` so the promo appears only once, and force-pushed. No release tags were affected.
- **Gemini CLI support.** Hooks go in `~/.gemini/settings.json`, next to the user's own settings and hooks. A backup is kept, and the handler is named `clawd-wars` so `/hooks disable clawd-wars` works. Gemini CLI uses its own event names, which the hook translates: `BeforeAgent` → prompt, `BeforeTool`/`AfterTool` → tool calls, `AfterAgent` → done (its `prompt_response` becomes the reply), and a `ToolPermission` notification → needs you. Timeouts are in milliseconds there. Its tools are described like Qwen's (`replace`, `write_file`, `run_shell_command`, `grep_search`, `list_directory`, `write_todos`…).
  - `~/.gemini` is shared with Google's newer Antigravity CLI, so Gemini CLI counts as installed only when a `gemini` command exists. The app looks in Homebrew, `/usr/local`, `~/.local`, npm-global, nvm, Volta, Bun, pnpm, Yarn, asdf and mise, because an app's own PATH is bare.
- **GitHub Copilot CLI support.** Our hooks get a file of their own, `~/.copilot/hooks/clawd-wars.json` (`"version": 1`, flat entries with `bash` and `timeoutSec`), which is deleted on uninstall. Using PascalCase event names gets Copilot's Claude-compatible payloads (snake_case fields, Claude tool names), so nearly everything maps directly.
  - `SubagentStart` only exists in camelCase. That one entry is camelCase, and the hook converts the payload (`sessionId`, `agentName`, `agentDescription` → the agent's task).
  - Copilot's `SubagentStop` carries an id its start event never sent, so a Copilot agent that can't be matched by id removes the oldest agent of the same type.
  - Like Gemini, it only counts as installed when a `copilot` command exists. A `~/.copilot` folder alone can come from Copilot in VS Code.
- Gemini CLI (gold) and Copilot CLI (mint) get their own outline colours and list sections, take sides like the others, and are covered by the hook health checks, the first-launch offer and Settings → Install/Remove … Hooks.
- **Claude Desktop vs Claude Code CLI.** Claude Code sessions started from the Claude desktop app get their own "Claude Desktop" section in the window and the menu, and are labelled "Claude Desktop" on cards, hover cards and menu lines. VS Code sessions say "Claude · VS Code".
  - The hook reads `CLAUDE_CODE_ENTRYPOINT`, which Claude Code passes to every hook. Verified on this Mac: `claude-desktop` for the desktop app and `cli` in a terminal. It's stored per session as `client`.
  - Sessions without hooks are recognised by where the `claude` binary lives: `~/Library/Application Support/Claude/claude-code/…` is the desktop app, and `…/extensions/anthropic.claude-code…` is VS Code.
  - Desktop sessions (and their agents) get a coral outline so they stand out from terminal Claude's white. The same colour is used for their section header and card portraits. They're still Claude, so they take Claude's side. Clicking a desktop session brings the Claude app forward.
- The hook takes `--event <name>` for AIs whose payloads don't name the event or use their own names. `StatusStore.normalize` translates the payload before `apply`.

### Fixed
- **Sides with old sessions.** A session recorded before sessions had a start time fell back to its last-update time, which keeps moving, so the oldest AI could look like the newest and the side rule flipped. A missing start time now counts as the oldest.
- **npm-installed AIs that launch a child process.** The scan found both the npm wrapper and the real process, kept the wrapper, and dropped the process actually running the hooks. For Codex, Qwen, Gemini and Copilot it now keeps the child; Claude keeps its old rule for nested runs.

### Changed
- **Window title bar redesigned.** The system close/minimize buttons are gone. The location name moves to the left, and the right side has our own buttons:
  - The **collapse** button (arrows pointing in) hides the session list, leaving just the scene strip. It then becomes an **expand** button (arrows pointing out) that brings the full view back. These replace a minus sign and a chevron, which read like "minimize window" and "menu".
  - **×** quits Clawd Wars. Window mode is remembered, so the next launch opens the window again. ⌘W still closes the window and switches to desktop mode.
  - The location name, collapse icon and close × all share the bar's vertical centre, measured on a real non-Retina window. The × is drawn by hand because the built-in xmark symbol's odd pixel height left it half a pixel low.
  - **Contents centred on the bar as you see it.** Several scenes (the cantina, for one) start with a dark ceiling beam that blends into the bar, so the bar looked 40 px tall and its correctly centred contents looked too high. The scene now measures how many of its top rows are dark (average brightness under 0.24, up to 10 pt). The label and buttons centre on bar + band; scenes with a light top centre on the bar alone. This replaces a short-lived bottom separator line, which didn't help.
  - Both highlight on hover (the close button turns red) and have tooltips. The rest of the bar still drags the window, and ⌘W still closes it.
- **Settings → Show Session List in Window** (on by default). Turned off, the window becomes just its header and the location scene: the list is hidden and the window locks to that height. Turning it back on restores the height you had, or fits the sessions if Fit Window Height is on.
- **Hover cards in window mode only appear when the session list is hidden.** With the list showing, the same details are already right below the scene, so the pop-up just got in the way. The desktop is unchanged.
- "Fit Window Height to Claudes" is now "Fit Window Height to Sessions", since the window lists every AI, not just Claude.
- **Agents hang in a tree under their session.** In each session's card, a trunk runs down from the session and branches into each agent row (├ … └ with a rounded last corner), in the project's colour. The agent rows are indented 20 pt beneath it, so it's clear who each agent belongs to.
- **Agent rows in the window carry a small "AGENT" tag** before the agent's name, a grey pill like the status chips. Being nested inside the session's card was the only cue before, which was easy to miss.
- **Expanding the window near the bottom of the screen keeps it on screen.** With Fit Window Height off, bringing the list back restored the old height by growing the window downward, past the screen edge. Both resize paths now keep the window inside the visible screen: it grows upward when there's no room below, and never gets taller than the screen.
- **The menu no longer lists the sessions.** The menu bar helmet, right-click and the top-bar Crew menu now open straight onto the options. The window's list and the desktop's hover cards already show every session. ⚠︎ items for hooks that need fixing still sit at the top when there are any.
- **Top-bar menus while the window is in front.** macOS only shows an app's menus with a Dock icon, so with Show Dock Icon off there was nothing up there when Clawd Wars was active. Now, in window mode, the Dock icon and the Clawd Wars / Crew / Window menus appear while the window is the active app and disappear when you switch away. With Show Dock Icon on, nothing changes.
- Window cards lose the thick accent bar on their left edge. The card's border, in the project colour, is now the same width all the way round.
- Settings lists Install/Remove Hooks for every supported AI found on the Mac, generated from `HookInstaller.others`. Cards name the reply's author by AI ("Gemini: …") instead of always "Claude:".

## 2.20.0 — 2026-10-10

### Added
- **Hook health checks for every supported AI, but only the ones installed on this Mac.** Claude Code counts as installed when `~/.claude/projects`, `~/.claude.json` or `~/.claude/settings.json` exists (`~/.claude` alone isn't enough, since Clawd Wars keeps its own state there). Codex and Qwen Code count when `~/.codex` or `~/.qwen` exists. Two things are checked every 10 s:
  - **Installed but not connected.** A banner says "Codex isn't connected", and a **⚠︎ Connect Codex…** item at the top of the menu installs the hooks in one click.
  - **Connected but silent.** A session started after our hooks were written, has been seen working (so a turn ran and a live hook would have fired), yet never reported. For Codex this means the hook hasn't been approved in `/hooks`. The card shows "APPROVE IN /hooks" (other AIs: "NOT REPORTING"), and the hover card, menu line and banner say what to type.
  - Requiring the session to have been busy avoids a false alarm on a freshly opened, idle Codex that hasn't fired any event yet.
- **macOS notification for silent sessions**, once per session: "Approve Clawd Wars in Codex — type /hooks in Codex and approve Clawd Wars (project) to see its live status." Clicking it jumps to that session. Notifications are skipped in playground, demo, chaos and frame-dump runs.
- Process scan records each process's start time (`kp_proc.p_starttime`); the silent check compares it with the hook file's modification time.

- **Each AI looks different.** Sprites get an outline in their AI's colour: white for Claude (as before), cyan for Codex, lavender for Qwen Code. The colours are always light, never black, so they read on any desktop wallpaper. Agents take their session's colour, and the window's card portraits match.
- **The list is split by AI.** With more than one AI running, the window's cards are grouped Claude Code → Codex → Qwen Code, each group under a small coloured divider ("CODEX ────"). The menu bar list gets the same sections. With one AI there are no headers, so nothing changes.
- `--ais=claude,codex,qwen` playground flag: assigns an AI to each playground session (cycled), to check outlines and grouping.

### Changed
- **The first-launch offer covers every AI that's on the Mac and not yet connected**, not just Claude Code. Each AI is offered once (`offeredHooks.<name>`), so someone who connected Claude Code earlier and installs Codex later is asked about Codex on next launch. The offer explains Codex's one-time `/hooks` approval up front.
- The red OFFLINE banner is now only for an unreadable status file. A missing hook shows as the AI-specific banner above, and no longer appears when Claude Code isn't installed at all (e.g. Codex-only users).

## 2.19.0 — 2026-10-10

### Added
- **Qwen Code support.** Qwen Code's hooks are Claude Code-compatible (same events and payload fields), so the same hook binary runs with `--assistant qwen`.
  - Installed into `~/.qwen/settings.json`: existing settings and the user's own hooks are kept, a backup is made, ours use matcher `.*` (Qwen matchers are regexes) and a name so they can be toggled in Qwen's `/hooks`. No trust step is needed.
  - Qwen's tools are described like the others: `run_shell_command` → "Bash: …", `edit` / `write_file` / `read_file` → "Edit/Write/Read <file>", plus grep, glob, web fetch and search, todos, and `task` subagents (whose descriptions become agent tasks).
  - `qwen` processes are found too, so sessions without hooks still appear.
  - Settings has Install/Remove Qwen Code Hooks. `--install-hooks` and the first-launch offer install hooks for every AI found on the Mac.
  - Verified against a sandbox `settings.json` (install, keep, uninstall) and with simulated Qwen events. Qwen sessions take sides like Codex.
- After installing hooks, the app says when Codex needs its one-time `/hooks` approval.

### Changed
- `HookInstaller` describes other AIs generically (`OtherAI`: config file, events, matcher spelling, timeouts). Codex and Qwen share the install/uninstall code.
- With three or more AIs running, the first AI keeps its side and every other AI takes the opposite one.

## 2.18.0 — 2026-10-10

### Added
- **Codex support.** OpenAI's Codex CLI sessions show up next to Claude's, with the same live status (working, thinking, needs you, subagents and their tasks, current tool) and click-to-jump.
  - Codex's hooks use the same event names and payload fields as Claude Code's, so one hook binary serves both: `--assistant codex` tells it which AI is calling.
  - The installer writes `~/.codex/hooks.json` (backup kept, existing hooks preserved). Codex runs new hooks only after you trust them with `/hooks`.
  - Codex's `Interrupt` (Esc) event sets the session idle straight away.
  - Its `apply_patch` edits show as "Edit <file>", and its shell tools as "Bash: …".
  - `codex` processes are found too, so Codex sessions without hooks still appear.
  - Cards, hover cards and the menu say Claude or Codex for each session. Settings has Install/Remove Codex Hooks, and `--install-hooks` / `--uninstall-hooks` handle both.
- **Light side vs dark side.** Heroes and villains are now one cast of 30, and anyone can be a session (drawn large) or an agent (drawn small).
  - With one AI running, characters are random from the whole cast.
  - When a second AI starts, the AI that was there first keeps the side it mostly has (ties go to its first character's side), and the other AI takes the opposite side. Claude with Vader means Codex gets heroes. Each AI's agents join their session's side.
  - A side borrows from the other only when all its own characters are on screen.
  - When one AI closes, it's random again. Existing characters never change.
  - Verified with simulated scenarios: one AI, Claude-first, light-majority-first, closing an AI, exhausted side, agent sides, and Vader/Kylo spacing.
- A hero leading an idle session rests: saber off, blaster lowered. Han gets his Falcon exit as a session too.

### Changed
- Cast ids: villains keep 0…, heroes are 100 + hero index. Agent records carry `cast` (older records fall back to their hero index), and session records carry `assistant`.

## 2.17.4 — 2026-10-10

### Changed
- README: new images of Han's Millennium Falcon departure (a four-step strip) and a desktop hover card. The window screenshots are re-shot without project names over the Claudes (the new window default), and the text explains per-mode labels and the optional fixed window height. The locations sheet always shows the Modal Nodes in the cantina.

## 2.17.3 — 2026-10-10

### Changed
- Project names over the Claudes are remembered per mode: shown by default on the desktop, hidden by default in the window (its cards already name every project). Settings → "Show Project Names on Desktop" / "… in Window" toggles the current mode's choice, which is saved and survives restarts; existing desktop settings carry over. Agents' task labels always show.

## 2.17.2 — 2026-10-10

### Changed
- The cantina's band is now random: each time the cantina comes up (at launch, or on switching to it) it's either Figrin D'an and the Modal Nodes or the Max Rebo Band, on the same stage. The stage is widened to 66 px to fit either. The Max Rebo Band still plays in Jabba's palace.

## 2.17.1 — 2026-10-10

### Fixed
- Droopy McCool now matches the film (checked against Wikipedia and starwars.com): an eyeless Kitonak playing a slim chindinkalu flute, instead of a horn and two little eyes. The band is the original three-piece lineup (Max Rebo, Sy Snootles, Droopy McCool), not the Special Edition one.

## 2.17.0 — 2026-10-10

### Added
- **Han leaves on the Millennium Falcon.** When Han Solo's agent finishes, instead of fading out:
  1. the Falcon swoops in over his head toward the open side of the screen and lands beside him (landing gear down);
  2. the ramp lowers, Han walks over and up it, and the ramp closes;
  3. the engines glow blue and it lifts off and flies away.
  The whole thing takes 6 s. The Falcon is drawn in code as a saucer seen slightly from above: central hatch, split front mandibles with the cargo gap, side cockpit, radar dish, engine glow.
- Developer aids: `CLAWD_SHOT` accepts `%d` for numbered frame sequences, with `CLAWD_SHOT_EVERY=<seconds>` (default 5), and `CLAWD_DISMISS_AFTER=<seconds>` makes Playground agents finish, for testing departures.

## 2.16.0 — 2026-10-10

### Added
- The cantina band as seen in the film: **Figrin D'an and the Modal Nodes**, four Bith with their instruments. Figrin D'an plays a kloo horn (black, silver keys, flared bell), Doikk Na'ts the Fizzz, and Ickabel G'ont and Tedn Dahai fanfars. Each bobs on their own beat.
- **The Max Rebo Band** in Jabba's palace: Max Rebo (blue Ortolan with floppy ears and a trunk) at his red organ with blinking keys, Sy Snootles (thin yellow-green singer with the long lips) at a microphone stand, and Droopy McCool (chubby pale Kitonak) on his long horn.
- **The bar crowd** in the cantina: Wuher the bartender behind the counter polishing a glass, and Dr. Cornelius Evazan (scarred face, dark coat) with Ponda Baba (Aqualish, tusks) leaning on the end of the bar.
- **Chaos test** (`--chaos[=seconds]`, a developer tool, hidden from users). Every half second it randomly adds and removes Claudes (up to 7) and agents (up to 12) and flips their moods, while checking that:
  - no character is off screen after walking in;
  - nobody walks for more than 8 s;
  - every session and agent appears within 3 s;
  - there are no extra characters;
  - labels stay on screen and never overlap.
  It prints a report and exits non-zero on violations. First runs: 90 s on the desktop (36 agents) and 90 s in window mode (43 agents), no violations.

### Changed
- README: describes both bands, the bar crowd, hover cards, walk-ins, sitting idle, NOT REPORTING and the OFFLINE banner. `docs/locations.png` and `docs/window-cantina.png` are regenerated.

## 2.15.3 — 2026-10-10

### Fixed
- Everyone now stands on the same pixel row. Measured every character's lowest pixel; feet should end on row 43:
  - Vader, Kylo, Dooku, the Emperor, Leia and the Jawa stood 1 px lower because their capes, robes and gowns hung one row past the feet. Hems now end on row 43.
  - The tauntaun stood 1 px higher (feet one row short).
  - Jabba floated 1 px when laughing. His belly now stays planted and only the upper body bobs.
  - The Gamorrean's resting axe and the Rancor's resting claw poked below the floor. The axe is now shouldered and the claw hangs forward.
- Positions saved under the older snap rule were still 1 px too low after the snap fix, because the fix only ran while dragging. The saved position is now re-snapped on launch and on Reset Position.

## 2.15.2 — 2026-10-10

### Changed
- Releases are notarized by Apple and stapled (via the `clawd-wars` notarytool keychain profile), so the downloaded app opens without a Gatekeeper warning. The Homebrew cask no longer needs to clear the quarantine flag.

## 2.15.1 — 2026-10-10

### Fixed
- Snapping the crew to the bottom of a screen put them 1 pixel too low. The snap treated all 8 canvas rows under the feet as empty, but the bottom row holds the feet's white outline, which ended up just below the screen edge. The snap now leaves 7 rows, so the outline sits on the edge.
- The Homebrew cask uses the current Homebrew syntax: `depends_on macos: :ventura`, and the quarantine-clearing step as a `postflight_steps` `run` step with an `{{appdir}}` path (was the deprecated `postflight` / `system_command`). `brew style` and `brew audit` pass. `release.sh` writes the new form.

## 2.15.0 — 2026-10-10

### Added
- **Homebrew install**: `brew install --cask rodclemen/tap/clawd-wars`. `release.sh <version>` does the whole release:
  1. builds a universal app (arm64 + x86_64, via `lipo`), signed with the Developer ID, hardened runtime, a secure timestamp, and the Apple Events entitlement so click-to-jump keeps working;
  2. notarizes and staples it when a `notarytool` keychain profile named `clawd-wars` exists;
  3. zips it, tags it and publishes a GitHub release with the CHANGELOG section as notes;
  4. writes the cask into `rodclemen/homebrew-tap`. Until releases are notarized, the cask clears the quarantine flag after install. Uninstalling the cask removes the hooks; `--zap` also removes settings and the status file.
- `build.sh --release <version>` makes the universal, distribution-signed build without installing it. The app version now comes from the newest CHANGELOG entry.
- **First-launch offer** to connect to Claude Code (install the hooks) when the app wasn't set up by `build.sh`, e.g. installed from Homebrew. It's asked once and can be done later from Settings.
- **`llms.txt`**: a guide to the repo for AI coding tools (build and run, code map, sprite conventions, how to add characters, fight rules).

## 2.14.0 — 2026-10-10

### Added
- **Hover details** (from agent-view): hovering any villain or agent, on the desktop or in the window, shows a card beside it, kept on screen. For a Claude: name and project, status and duration, current activity, your last prompt, agent count, and "Click to jump". For an agent: its task, current tool, age and tool count, and which Claude it belongs to. Agents now take hover and clicks on the desktop too (a click jumps to their Claude).
- **Walk-ins** (from agent-view's door): new Claudes and agents walk in from the side, 240 pt × zoom away, one at a time with 0.6 s between them, instead of fading in where they stand. On launch everyone is simply in place.
- **Staged idle**: a lone idle Claude stands for 2 minutes, then sits down (legs folded, body on the floor, cape stopping at the floor), and shows zZz after 5 minutes. Walkers, Jabba, the Rancor and the Emperor stay standing. Claudes that are fighting don't sit.
- **Explicit offline state** (from agent-view): a pulsing red OFFLINE banner over the crew on the desktop when the hooks aren't installed or the status file can't be read (the window shows it above the cards). A session the hooks still call idle, whose process has been busy for over a minute with no agent reporting, is marked **not reporting**: "?" bubble, NOT REPORTING on its card, and a hover note to restart it.
- Debug and screenshot aids: `CLAWD_HOVER=<key>` pretends to hover a character, `--mood=idle|thinking|waiting|working` sets the Playground mood at launch, and Playground "Idle" spreads villains across the idle stages.

## 2.13.1 — 2026-10-10

### Added
- Ready to share as a public repo:
  - MIT `LICENSE`, so the code is free to use, change and share. It's the plain MIT text so GitHub recognises it; the trademark note (Star Wars belongs to Lucasfilm/Disney, Claude and Clawd to Anthropic) lives in the README footer.
  - README badges (MIT, macOS 13+, Swift, for Claude Code, free to use), a Contributing section on how to add a villain, hero or location, and a License section.
  - `docs/social-preview.png` (1280×640), the link card for X, Slack, Discord and iMessage, rendered by `Tools/RenderDocs`.
  - GitHub description and topics.

## 2.13.0 — 2026-10-10

### Added
- A GitHub README with the pitch up top, the icon, a desktop battle strip, the full roster, window-mode screenshots in the Mos Eisley Cantina and on Hoth, and a grid of all 22 locations. Images live in `docs/`.
- `Tools/RenderDocs`: renders `docs/roster.png` (every villain and hero, labelled, mid-action) and `docs/locations.png` (every location with its animation frame) with the app's own sprite code. Window and desktop screenshots are made with `CLAWD_SHOT` and the Playground.
- Playground sessions get realistic sample details (model, current activity, last prompt and reply, prompt and tool counts, uptime, and each agent's activity, age and tool count), so their cards look like live ones.

## 2.12.0 — 2026-10-10

### Added
- **Greedo** villain: a green Rodian Clawd with huge glossy black eyes, a tapir snout, head spines and ear fans, a dark vest over a pale tunic, and his small blaster pistol (bolts leave from its muzzle). Home: the Mos Eisley Cantina.

## 2.11.2 — 2026-10-10

### Fixed
- The Rancor's card portrait was shown at 1× because the redrawn upright rancor is 42 px tall. The portrait box is now sized from measured maxima across all villains (widest: AT-AT, 53 px; tallest: Rancor, 42 px) to 112×86 pt, so every portrait fits at 2×.

## 2.11.1 — 2026-10-10

### Changed
- The rancor is now just "Rancor" and redrawn to match the film (per the Star Wars databank): upright on two short, stubby legs with three-toed feet, a tall torso hunched forward, spines along its back and shoulders, scaly grey-brown hide, a flat face that's mostly fanged mouth with tiny eyes, and disproportionately long arms. One arm hangs almost to the ground; the other swipes from below the jaw.

## 2.11.0 — 2026-10-10

### Added
- **The Rancor** villain: a hulking brown beast-Clawd with warty hide, a huge fanged mouth, tiny yellow eyes, thick clawed legs and a hanging arm. It fights with claw swipes on its other arm (melee, so it duels sabers).
- **Rancor Pit** location under Jabba's palace: rough stone, the keeper's barred gate, bones and skulls on the floor, and light falling through the grate above with drifting dust.

### Fixed
- The card portrait box is 80 pt tall (was 76), so the rancor shows at 2× instead of dropping to 1×.

## 2.10.0 — 2026-10-10

### Added
- **Tauntaun** hero (agent): a shaggy grey-white biped with curled horns, a long snout, two big feet and a swishing tail. It's unarmed like R2-D2 and C-3PO, so it doesn't fight. It stomps now and then, bobs its head, and huffs frosty breath. Home: Hoth.

### Changed
- The location name in the window's title bar is back to its earlier style (10.5 pt semibold, light grey, uppercase) instead of crawl-yellow, and stays on the right.

## 2.9.1 — 2026-10-10

### Fixed
- The AT-AT (and other wide characters) were cut off in the window's cards. Portraits used a fixed crop sized for a standard Clawd. They are now cropped to each character's visible pixels (`PixelCanvas.opaqueBounds`) and drawn as large as fits, up to 2× (whole-number scales keep pixels crisp), centred at the bottom. The portrait column is widened to 112 pt so the AT-AT fits at 2×. Agent portraits use the same fitting.

## 2.9.0 — 2026-10-10

### Added
- **AT-ST** villain: a grey cockpit Clawd (viewport slit, side pods, chin guns) on two long, backward-bending legs with wide feet that step when walking. Fires from its chin guns. Home: the Forest Moon of Endor.
- **AT-AT** villain: Clawd as the walker's body (it already had four legs), with armour plates, neck, head with viewport and snout, and heavy chin cannons. Home: the Battle of Hoth.
- **Wicket the Ewok** hero: a small furry Clawd in a leather hood with ears poking through, big dark eyes, and a stone-tipped spear that fights as a melee weapon (duels sabers). Home: Endor.
- Two locations: **Forest Moon of Endor** (giant redwoods, Ewok huts on platforms with rope ladders, ferns, forest floor) and **Battle of Hoth** (snowfields and mountains, the shield generator dish, the Rebel trench with a turret, falling snow).
- `Leader.muzzle`, so a walker's bolts leave from its chin guns in fights.

### Changed
- The window's title bar shows only the location name, right-aligned in crawl-yellow. The CLAWD WARS title and the yellow rule under the bar are removed.

## 2.8.0 — 2026-10-10

### Changed
- New **Settings** submenu in every menu (menu bar helmet, Crew, right-click) holding the preferences: Size (desktop only), Show Project Names, Keep Window on Top, Fit Window Height to Claudes, Show Dock Icon, Launch at Login, and Install/Remove Claude Code Hooks. The top level keeps the everyday actions: session status, Show in Window/Desktop, Location, Forget Idle Sessions, Reset Position (desktop only) and Quit, plus Playground and Demo with ⌘.
- The pin capsule is gone from the window's title bar; it's now Settings → Keep Window on Top.

## 2.7.2 — 2026-10-10

### Changed
- The window's green maximise button is hidden, full screen is disabled (`.fullScreenNone`), and double-clicking the title bar no longer zooms. Width is resized by dragging the edge, and height follows the Claudes (or is set by hand when auto-height is off).

## 2.7.1 — 2026-10-10

### Fixed
- Cards no longer leave a scrollbar-sized gap on the right, or shift sideways when the window changes height. The card area uses overlay scrollers (re-applied on resize, because macOS can switch back to legacy scrollers when a mouse is connected), and cards are sized to the scroll view's full width, so both margins are 12 pt. Auto-height pauses while you drag the window edge and settles when you let go (`windowDidEndLiveResize`), so the cards don't jump around mid-drag.

### Added
- "Fit Window Height to Claudes" toggle in window mode (on by default). With it off, the window keeps whatever height you give it, and the cards scroll if needed.

## 2.7.0 — 2026-10-10

### Changed
- Window mode has a themed title bar instead of the grey system one. The window uses a full-size content view with a transparent, title-less system bar, and the traffic lights stay. In their place is a `HeaderView` in the current location's colours, with a thin crawl-yellow rule, **CLAWD WARS** in condensed bold crawl-yellow (Futura Condensed ExtraBold, falling back to Helvetica Neue Condensed Black), and the location's name. Dragging the bar moves the window and double-clicking zooms it. The "Keep on top" checkbox is replaced by a yellow pin capsule in the bar (filled "◉ ON TOP" when pinned). The bar redraws when the location changes, and auto-height includes it.

## 2.6.2 — 2026-10-10

### Changed
- "Show Dock Icon" now applies in both desktop and window mode (on by default). With it on, Clawd Wars has a Dock icon and an app menu bar (app menu + Crew menu) in both modes. With it off, it's a menu-bar-only accessory in both, reached through the helmet. Clicking the Dock icon in window mode brings the window forward. The app menu's Show in Window / Show on Desktop label follows the current mode.

## 2.6.1 — 2026-10-10

### Added
- "Show Dock Icon in Window Mode" toggle (on by default). With it off, window mode keeps the app as an accessory: no Dock icon and no app menu bar. The menu bar helmet still has every option. Toggling it while the window is open re-shows the window, because changing the activation policy hides it.

## 2.6.0 — 2026-10-10

### Added
- The window sizes its height to its content: the scene strip plus one card per Claude, agent lists included. It grows and shrinks as Claudes and agents come and go, keeps its top edge in place, and stops at the screen's visible height (the cards scroll beyond that). The width stays under your control. Checked: 296 pt of content for one Claude, 524 pt for three.

## 2.5.1 — 2026-10-10

### Changed
- Playground and Demo Mode are hidden unless ⌘ is held while opening the menu: the Crew menu, the menu bar helmet or the right-click menu. While either is running, both stay visible so you can leave.

## 2.5.0 — 2026-10-10

### Added
- Menu bar icon: a Vader Clawd helmet cropped from the sprite, always present in desktop and window mode. It opens the same menu as right-clicking a villain (session status and agents, Show in Window / on Desktop, Location, Size, Playground, Demo, hooks, Quit). Checked with `VADER_DEBUG`: the item is visible on screen in the main display's menu bar.
- In window mode the app's menu bar gains a **Crew** menu with the same items.
- Both menus are rebuilt from live state each time they open (`NSMenuDelegate.menuNeedsUpdate`).

## 2.4.2 — 2026-10-10

### Changed
- Window mode always uses the Small size (0.67), still shrinking further if the window is too narrow. The location backdrops now use 2 pt pixels to match the crew, and the scene strip is shorter (170 pt; floor 20 pt, feet at 16 pt), leaving more room for the cards.

## 2.4.1 — 2026-10-10

### Changed
- Size is disabled in window mode; the menu shows "Size (desktop only)". The window always draws the crew at full size and shrinks it only to fit the window width, with a fixed scene height. Before, the desktop size setting also shrank the crew and the scene strip inside the window.

## 2.4.0 — 2026-10-10

### Added
- 19 window-mode locations (`Locations.swift`), each drawn as pixel art in code on shared helpers (banded gradients, stars, dunes, circles and ellipses, textured ground). On Automatic, the first-spawned Claude decides where the crew is:
  - Vader: Death Star corridor, with a viewport onto space
  - Boba Fett: Great Pit of Carkoon, with the sarlacc (tentacles waving) and Jabba's sail barge
  - Jabba / Gamorrean Guard: Jabba's palace throne room (dais, hookah, rancor grate, flickering torches)
  - Stormtrooper: the Mos Eisley cantina
  - Kylo Ren: Snoke's red throne room on the *Supremacy*, with Praetorian guards
  - Darth Maul: the Theed generator complex, with pulsing laser gates
  - The Emperor: Death Star II throne room, with Endor and the battle flashing in the round window
  - Count Dooku: Geonosis rock spires
  - R0-GR: the plains of Naboo, with Trade Federation tanks
  - IG-88: the *Executor*'s bridge (Star Destroyers outside, crew pits, blinking consoles)
  - Hero homes, chosen from the Location menu: Lars homestead under the twin suns (Luke), Obi-Wan's hut, the Jawa sandcrawler (Jawa, R2-D2), Dagobah with drifting fog (Yoda), the Millennium Falcon hold with a flickering dejarik game (Han, Chewbacca), the Tantive IV (Leia, C-3PO), the Jundland Wastes with a Tusken Raider and a bantha (Qui-Gon), Jakku with the crashed Star Destroyer (Rey), and the Jedi Council chamber over the Coruscant skyline (Mace Windu, Ahsoka).
- Window right-click menu → Location: Automatic (where the first Claude belongs), or pin any scene. Each entry lists who it belongs to.
- The card area takes on each location's tone (desert sand, Death Star grey, Supremacy red, Dagobah green…).

### Changed
- Each scene is cached per window size and location; only its animated layer is redrawn per frame.

## 2.3.0 — 2026-10-10

### Added
- Window mode is set in the Mos Eisley cantina (A New Hope). `Cantina.swift` draws the scene strip as pixel art: white-plaster adobe walls with a hand-finished texture, ceiling beams, hanging lamps with faint light shafts, arched booth alcoves (round table, lamp, bench), the curved bar with a brass rail and a shelf of glowing bottles, a packed-earth floor, and Figrin D'an and the Modal Nodes — three Bith on a stage, bobbing in time with music notes drifting up. The room is rendered once per window size and cached; only the band animates. The crew stands a little way into the floor.
- The card area is restyled as warm dark adobe with a plaster texture, and cards are warm-tinted to match. The window background follows.

## 2.2.0 — 2026-10-10

### Added
- **Show in Window** (right-click menu). A normal window with a Dock icon and menu bar replaces the desktop overlay. A starfield strip on top shows the crew, laid out and drawn by the same code as the overlay, with the strip acting as their "screen". The crew is centred and shrinks to fit the window width. Below it is one card per Claude:
  - villain portrait, name and project in its accent colour, plus a status chip with how long it's been in that state (WORKING · 2m 10s, THINKING, NEEDS YOU, IDLE, ASLEEP, NO LIVE STATUS, BUSY (CPU));
  - model and session title, what it's doing now ("Now: Edit Overlay.swift"), your last prompt, and its last reply when idle;
  - prompt and tool-call counts, uptime and working folder;
  - its agents, each with portrait, hero name, task, current tool, age and tool count.
  Clicking a card or a character jumps to that session. "Keep on top" pins the window. A red banner says so when the hooks aren't installed (from agent-view: never show stale data silently). Closing the window goes back to the desktop overlay, and the window remembers its frame.
- The hook records more per session: model and session title (SessionStart / UserPromptSubmit), last prompt, Claude's last reply (Stop's `last_assistant_message`), the current activity, tool and prompt counts, and when the state last changed. Tool calls are summarised as "Edit Overlay.swift", "Bash: swift build", "Grep fightRoles", "Fetch github.com", or "server: tool" for MCP. Agents get their current activity and tool count too.
- From [agent-view](https://github.com/HEM42/agent-view):
  - Status debounce: a new mood must hold for two refreshes, except "needs you", which shows instantly.
  - A "?" bubble for sessions without hooks, instead of pretending they're idle.
  - A zZz bubble after 5 minutes idle.
  - A "needs you" ignored for more than a minute makes the villain jump and wave, and the "!" flashes faster.
  - A bobbing yellow marker over the Claude whose terminal or VS Code tab is in front.
  - Project accent colours: collision-free, remembered, and shared by a Claude and its agents on label borders and cards.
  - Labels never overlap: Claudes get first pick and colliding labels move up a row.
  - `CLAWD_SHOT=/path.png` writes the rendered scene (or the whole window) every 5 s, so visuals can be checked without screen recording.

### Changed
- Speech bubbles go on the side away from the nearest neighbour, so it's clear whose bubble it is. When a bubble sits on the left, only its frame is mirrored; the "?" and zZz never read backwards.
- The "hooks installed" check matches the hook by name instead of exact path.
- Playground and Demo agents start their clocks when created instead of showing nonsense ages.

## 2.1.1 — 2026-10-10

### Added
- Version control: the project is now a git repository, pushed to a private GitHub repo (`rodclemen/clawd-wars`). `.gitignore` excludes `build/` (recreated by `build.sh`), personal `.vscode/` settings and `.DS_Store`.

## 2.1.0 — 2026-10-10

### Added
- Agents show what they're doing, in a label box above their head. `SubagentStart` only carries the agent's type, so the hook queues the `description` from each Agent/Task `PreToolUse` and gives it to the next agent of that type that starts in the same session (oldest first, any type as a fallback). Agents without a description, such as workflow agents, show their type ("Workflow Agent", "Explore"; general-purpose shows "Agent"). Checked with the live hook: two agents started in reverse order each got the right task.
- Agent label boxes are blue-tinted with a smaller font and an 88 pt × zoom max width (two lines), so they fit between neighbours and stand apart from the grey project-name boxes over Claudes.
- The right-click menu lists each agent as "Hero — task". Playground and Demo agents get sample tasks.

### Changed
- `AgentRecord` gains `task` and `StatusFile` gains a `pending` queue, pruned after 120 s or when the session ends. Both are optional, so state written by older versions still loads. Each companion also has a `headTop` so labels sit just above its hair, dome or helmet.

## 2.0.1 — 2026-10-10

### Changed
- Speech bubbles are about half the size: an 18×13 canvas with a 15×9 box, down from 28×18 and 23×12. They only ever hold three thinking dots or a "!", so the extra room was wasted. The dots are 2×2 squares and the "!" is a 3-pixel bar with a dot. Because the bubbles are smaller, a label pushed over a bubble needs to rise less.

## 2.0.0 — 2026-10-10

### Changed
- Renamed to **Clawd Wars**. The app installs as `~/Applications/Clawd Wars.app` and the executable is `ClawdWars`. `build.sh` removes the old `VaderClaude.app`, stops either process name, and re-points the Claude Code hooks at the new path (quoted, since it contains a space). The bundle ID (`com.rodclemen.vaderclaude`), the hook binary name and `~/.claude/vader-status` are unchanged, so the Accessibility grant, saved position and size carry over. Checked after the rename: the hook fires and Accessibility is still trusted.

### Added
- App icon: Vader Clawd and Luke crossing red and green sabers with a clash spark, on a pixel starfield over a Claude-orange horizon. It's drawn by `Tools/MakeIcon` with the app's own sprite code (outline included), stored as `Resources/AppIcon.png`, and turned into `AppIcon.icns` by `build.sh` (sips + iconutil).

### Fixed
- The project label of the rightmost Claude could run off the right edge of the screen, especially with two busy Claudes and their speech bubbles. Labels (and the "Roger roger!" / "Ho ho ho!" callouts) are now kept inside the screen. When the clamp pulls a label back over a speech bubble, it moves up to sit on top of the bubble.

## 1.9.5 — 2026-10-10

### Fixed
- Jumping to a VS Code native tab actually switches the tab now. Traced with the new `--jump` diagnostic: AXPress on the tab's AXRadioButton returned success (0), but VS Code (Electron) ignored it, even after being activated first. Jump still activates the app and presses the tab, then checks whether the window title changed. If it didn't, it opens the project folder in the same app. That folder is already open as a tab, so VS Code just focuses that tab and opens no new window. The folder path is cut from the session's cwd at the exact folder whose name matched a tab title, so a subfolder never opens a fresh window. Checked live: another project's tab came forward.

### Added
- `--jump=<pid> <logfile>` diagnostic: runs the click-to-jump path for a Claude process and logs each step (host app, cwd, windows and tabs seen, press result, fallback taken).

## 1.9.4 — 2026-10-10

### Fixed
- Clicking a villain now selects the right VS Code tab when `window.nativeTabs` is on. With native tabs, macOS exposes only one window per tab group, titled after the selected tab. The other projects exist only as AXRadioButton tabs in its AXTabGroup, so the old window-title search found nothing and just activated VS Code. Jump now searches every window's tab bar first and presses the tab whose title matches the session's project folder (deepest folder first, exact before substring), then raises that window. It falls back to window titles for apps without native tabs.

### Added
- `--ax-dump=<pid> [file]` diagnostic: lists the Accessibility trust status, the host app, the session's cwd, and every window and tab title the app can see. Run it with `open -n VaderClaude.app --args …` so it uses the app's own Accessibility grant.

## 1.9.3 — 2026-10-10

### Changed
- Project label boxes sit 5 pt higher above each villain's head (8 pt instead of 3 pt × zoom), so the box doesn't crowd the helmet or hood.

## 1.9.2 — 2026-10-10

### Changed
- Long project names wrap onto two centred lines in the label box (max width about 110 pt × zoom, roughly a villain's width). Lines break at spaces, dashes and underscores. A single word too long for one line fills the first line and continues on the second, and anything past two lines ends in "…". For example, "my long project name" shows as "my long / project name".

## 1.9.1 — 2026-10-10

### Fixed
- On stacked monitors the crew couldn't stand on the bottom edge of the upper monitor. The drag clamp chose the screen from the canvas bottom, which sits 8 rows below the feet. Once that point crossed into the lower monitor, the clamp used the lower monitor's limits and stopped the drag. Now the clamp uses the screen under the cursor while dragging (otherwise the one under the feet). The empty rows under the feet may hang off the edge, and feet dropped within 12 pt of a bottom edge snap onto it. Checked against the real layout: dragging past the upper monitor's bottom puts the feet exactly on its bottom edge, and the same on the lower monitor.
- Saved positions are validated by where the feet are, so a crew standing on an edge at a large size isn't reset on launch.

## 1.9.0 — 2026-10-10

### Added
- Four new villains:
  - Count Dooku: red saber, dark cape, white hair and pointed beard.
  - Gamorrean Guard: green pig face, horned leather cap and tusks; swings a vibro-axe (fights as melee, drawn as an axe, no glow).
  - Jabba the Hutt: a big slug body with a tail and slit eyes. Unarmed, so he joins the cheerers and calls "Ho ho ho!" instead of being paired into a fight.
  - IG-88: grey droid with a tall striped sensor head and a blaster rifle.
- Seven new heroes:
  - Saber users: Qui-Gon Jinn (long hair and beard, green), Mace Windu (bald, brown robes, purple), Yoda (green with big ears and a short green blade), Rey (buns, wraps, blue) and Ahsoka Tano (striped montrals, facial markings, twin white sabers).
  - Blaster users: Chewbacca (fur, bandolier, bowcaster) and a Jawa (hooded robe, glowing yellow eyes, ion blaster).
- White 1px outline around every character, so dark sprites read on a black desktop. Only fully opaque pixels are outlined, so saber glows and bolts stay clean.
- Project labels sit in a dark rounded box with white text and a faint border, readable on any wallpaper.

### Changed
- Agents are now random heroes not already on screen, the same way villains are. Before, the lowest free one was picked, so the new heroes would only appear with 7+ agents at once.
- The crew can sit right on the bottom edge of the screen. Each sprite has 8 empty pixel rows under its feet (24 pt at normal size), and dragging used to stop that empty space, not the feet, at the edge. "Reset Position" also puts the feet on the edge now.

## 1.8.0 — 2026-10-10

### Added
- R0-GR, a B1 battle droid, as a seventh villain. It's a tan droid Clawd with the long forward snout head on a thin neck, skinny legs and an E-5 blaster. It fights like the other blaster villains, and every 5 s it calls out "Roger roger!" on the side of its head away from the speech bubble. It's in the random spawn pool and the Playground.

### Changed
- Vader is no longer always first. The first session gets a random villain like everyone else, and the Vader/Kylo spacing rule still applies. Simulation: Vader came first in 287 of 2000 runs, about 1 in 7, with zero back-to-back Vader/Kylo spawns. The first-spawned villain stands on the saved spot and the crew lines up from there. An idle Vader appears only as a placeholder when no Claude sessions are running.

## 1.7.0 — 2026-10-10

### Changed
- Villains are assigned at random instead of in fixed order. The first session is still Vader (the crew forms around him). After that, each new session gets a random free villain, and Vader and Kylo never spawn one right after the other. A simulation of 2000 four-session sequences found zero Vader→Kylo or Kylo→Vader spawns. Sessions found only by the process scan use a pid-seeded pick so they keep the same villain between refreshes.
- Sessions are recorded with a `created` time, and the line is ordered by spawn order (Vader first) instead of villain index, so "who came after whom" matches what you see.

## 1.6.0 — 2026-10-10

### Changed
- New fight rules:
  1. Claudes always fight Claudes, whatever each one is doing. Their bubbles and labels still show status.
  2. Agents fight agents, across sessions.
  3. If one Claude and one agent are left over, they fight each other (one Claude + one agent = Vader vs Luke).
  4. Anyone else left over cheers, so a second session's Claude starts duelling Vader while a lone agent cheers them on.
  5. A lone Claude with nobody to fight does its normal kata when working.
  Within each group saber users pair first. R2-D2 and C-3PO remain bystanders.
- Fighting no longer depends on activity, so the activity window and the working/thinking check for fights are gone.

## 1.5.0 — 2026-10-10

### Added
- Everyone fights. Every armed character on screen pairs off, active villains and agents alike. R2-D2 and C-3PO stay unarmed bystanders. Pairing is greedy in priority order: villain vs agent saber duels (Vader vs Luke) first, then any saber vs saber, then villain vs agent, then whoever is left. Villains fight while their Claude is working or thinking (with a 3 s linger) and step out when idle or waiting on you.
- With an odd number of fighters, the leftover cheers: it hops twice a second, waves its saber overhead (blasters are raised, the Emperor crackles) and has blinking stars above its head.
- Agents take fight roles. Luke and Obi-Wan duel, deflect bolts and block lightning. Han and Leia shoot at their opponent with bolts drawn by the effects layer, and shake when zapped.
- `--agents=0,1,…` launch flag (pairs with `--playground=`) for testing.

### Changed
- Fight effects work between different-sized sprites. Each side is described by a `Fighter` (position, scale, canvas offset, facing, muzzle). Clash sparks are placed where the two mirrored blades actually intersect, bolts aim at the deflecting blade's peak position (or the target's body), and lightning targets the blocking blade.
- Saber duel distance scales with both sprites, so blades cross whether it's villain vs villain (170 pt), villain vs agent (~126 pt) or agent vs agent.
- `Weapon` is a top-level type shared by villains and agents. `fightRoles` and `fightIsCloseQuarters` take weapons instead of villains.

## 1.4.1 — 2026-10-10

### Fixed
- Duels never started with real sessions that predate the hooks. Those sessions only came from the process scan and were always idle, so they never counted as active and couldn't fight. Vader ended up swinging at an idle Kylo. Hook-less sessions now count as working while their claude process uses more than 3% CPU, sampled every 3 s and held for 6 s (measured: idle about 0.3%, working 5–10%). They still can't report thinking, permission prompts or agents until they're restarted with hooks.

### Added
- Debug aids: `--playground=0,1,…` starts the Playground with those villains, and `VADER_DEBUG=1` logs each villain's position, facing, mood and fight role twice a second.

## 1.4.0 — 2026-10-10

### Added
- Click a villain to jump to its Claude session. The app walks up from the claude process to the GUI app hosting it. In Terminal.app or iTerm2 it selects the exact tab by tty (AppleScript). In VS Code, Cursor and other editors it raises the window whose title names the session's project (Accessibility API). The project is matched deepest folder first and never opens a new window. A click is told apart from a drag by under 4 pt of movement. Playground and demo villains, which have no process, just beep.
- `build.sh` signs with your Developer ID / Apple Development certificate when one exists, so the Accessibility grant survives rebuilds. It falls back to ad-hoc signing.

### Changed
- Fight pairing is now dynamic instead of fixed slots (1st+2nd, 3rd+4th). Active saber users are paired with each other first, then the remaining active Claudes pair in order, and idle Claudes stand aside. Before, a third lightsaber Claude practised next to a duelling pair, facing the same way as its neighbour. Now any two active saber Claudes walk over and duel. The line keeps session order, so it only reshuffles when someone starts or stops working.

## 1.3.0 — 2026-10-10

### Added
- Playground (right-click → Playground) for previewing villains and matchups without real Claude sessions:
  - Tick any of the six villains to put them on screen. They pair up and fight in the order you add them, so you pick the matchups (e.g. Boba then Vader to watch deflections, Emperor then Maul for saber-vs-lightning).
  - Tick any of the six agents; they join the first villain.
  - "Villains Are…" switches everyone between Working (fighting), Thinking, Waiting for you and Idle.
  - "Add All Villains" adds the whole roster; "Exit Playground" goes back to live status.
  - Turning on Demo Mode leaves the Playground, and vice versa.

### Changed
- Project labels now sit just above each villain's helmet or hood instead of under its feet. Each villain has its own head height (Boba's clears his antenna), and if a speech bubble is showing on that side, the label slides away from it.

## 1.2.0 — 2026-10-10

### Added
- Session discovery from the process table (`Sources/Shared/Processes.swift`). The app scans for interactive `claude` processes every 3 s and reads each one's working directory, so every open Claude Code session gets a villain and project label even if its hooks never fired. Claude Code only loads hooks at startup, so sessions started before the install were invisible. Sessions found this way show as idle, and the menu marks them "no live status (restart this Claude session)".
- The hook records the PID of the Claude process that ran it. The app and the hook both drop a session (and its agents) the moment that process exits, which replaces the 3-hour stale timeout for anything with a PID.

### Changed
- Records without a PID are matched to a running process by project folder, so a session isn't counted twice while it upgrades.

## 1.1.0 — 2026-10-10

### Added
- Several Claudes at once: each Claude Code session gets its own Clawd villain (Vader, Kylo Ren, Darth Maul, Boba Fett, Stormtrooper, Emperor) with its own mood and its own agents. The hook stores the leader index and project folder per session, and the overlay labels each villain with its project name. You can turn the labels off in the menu.
- Fights between paired Claudes when both are working. Saber vs saber steps in to a synced duel with clash sparks where the blades cross. Blaster vs saber shoots bolts, and the defender's swing is timed to deflect each one up and away. Emperor lightning is caught on a saber blade or zaps a blaster user. Blaster vs blaster is a shootout. A fight carries on for 3 s after one side stops working, so the gaps between tool calls don't break it up.
- Proper blasters drawn from the film designs: Han's DL-44 (scope, conical flash hider, wood grip), Leia's Defender sporting blaster (chrome slide), the Stormtrooper's E-11 (scope, magazine, cooling holes) and Boba's EE-3 (brass fittings). Boba's jetpack fires while he shoots.
- Walking: every character walks (stepping legs, facing the way it's going) to its spot in the formation, so the crew shifts as a group to stay on screen and walks back home afterwards.
- Menu items: Show Project Names and Forget Idle Sessions (clears sessions whose terminal closed without a clean exit). There's also a `--demo` launch flag.

### Changed
- Layout: the fixed slot window is replaced by a formation laid out toward the side of the screen with more room. Every sprite faces open space, the window resizes to fit what's drawn, and the layout reserves saber room so the crew doesn't jitter between thinking and working.
- Thought and "!" bubbles are drawn separately from the sprite and flip to whichever side of the head fits on screen.
- A "thinking" status within 3 s of a tool call still counts as working, so the lightsaber kata no longer flickers between tool calls.
- Dragging keeps Vader and his bubble fully on screen. Any villain can be grabbed to move the whole crew.
- Idle scenes render at 10 fps instead of 30 to cut CPU use.

### Fixed
- Sessions recorded before 1.1 had no leader assigned. The hook now fills one in on the next event, so an existing session doesn't keep showing as the wrong villain.

## 1.0.0 — 2026-10-10

### Added
- Darth Clawd: a transparent, always-on-top desktop overlay (status-bar window level, every Space, full-screen apps) showing Clawd in a Vader helmet, cape and chest box. All sprites are procedural pixel art drawn at runtime, so there are no image assets.
- Mood animations: idle breathing, a thought bubble while thinking, a looping lightsaber kata while running tools (with motion trails), a red "!" bubble while a permission prompt waits, and a lit-saber guard stance while agents run after Claude itself has stopped.
- Subagent companions, assigned in this order: Luke (green saber kata), Han and Leia (blaster fire with muzzle flash and bolts), Obi-Wan (blue saber), R2-D2 (rocking, blinking dome light, music notes) and C-3PO (flailing arms). They fade in and out, sit in slots around Vader, gather on the side with more screen room, and mirror on the left so their weapons point outward.
- Drag-to-place: only Vader's body takes clicks and the rest of the overlay is click-through. The position is saved between launches, and the agents follow him.
- Right-click menu: live status and agent roster, Size (Small/Medium/Large/Huge), Demo Mode, Reset Position, Launch at Login, Install/Remove hooks, Quit.
- `vader-hook`: a Foundation-only binary for fast startup that Claude Code runs on 12 hook events. It writes `~/.claude/vader-status/state.json` under `flock`, merges multiple sessions, and expires stuck states because Esc interrupts fire no hook.
- `build.sh`: builds the app, ad-hoc signs it, installs to `~/Applications`, merges the hooks into `~/.claude/settings.json` (backup in `settings.json.before-vader`) and launches it.

### Fixed
- The overlay had dropped to floating level: `isFloatingPanel = true` was overriding the status-bar level, so some windows could cover it.
- First launch now places Vader on the screen under the mouse. Before, it used AppKit's "main" screen, which on a stacked two-display setup can be the display you're not looking at.

---

*Taught a crab the ways of the Sith, then gave it rivals. Spent more time on the blaster deflection angles than on anything with actual business value.*
