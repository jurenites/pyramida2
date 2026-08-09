# Pyramida 2 — Foundation Specification

Status: living, editable specification for the first clean-room prototype.

This document records agreed rules. [GLOSSARY.md](GLOSSARY.md) records the canonical project terminology. This specification is deliberately smaller than a complete game-design document. The first implementation should prove the peaceful gathering, carrying, construction, navigation, and visual-building loop before the deferred systems are added.

[WORLD_STREAMING_AND_PERSISTENCE.md](WORLD_STREAMING_AND_PERSISTENCE.md) is the approved, implementation-ready next major milestone for the semi-infinite world: north/south biome latitude, fog-driven horizontal expansion at every Citizen height, deterministic seed regeneration, sparse save deltas, and forecasted outside-settlement simulation. It is deliberately deferred until the next dedicated world-streaming batch rather than remaining an unresolved design topic.

## 1. First playable scope

The first playable version is a peaceful, vegetarian construction sandbox inspired by the basic loop of Sokpop's *Pyramida*, with original code and assets.

Include first:

- Citizens with `Idle`, `Walk`, `Carry`, and `FreeFall` states.
- Renewable bushes or wild crops that produce a single `Calories` resource.
- Bushes occupy one World Unit, have a small bounded deterministic offset, display ten berries, and grow in deterministic irregular patches rather than as independently scattered points.
- Trees that can be planted and cut into physical logs. The generator makes separated irregular forest patches, clear land, and one or two standalone Trees between forests rather than a uniform repeating scatter. Living Trees may initially appear as 1, 1.5, 2, 2.5, or 3-World-Unit growth stages and mature by half-World-Unit stages up to a strict three-World-Unit limit. A living Tree is a connected vertical stack with one log segment per World Unit and slight inherited deviation between segments. Roots cover the trunk entry at ground level. Internal caps between trunk segments are not rendered. Only the top segment has three or four branches plus smaller twigs branching from them. Several solid-green low-poly forms make its crown, with more crown forms on taller Trees. Trunk, branches, and crown sway as one connected assembly. Dead Trees use the connected trunk and top branches without greenery. Cutting is timed work shown by a reusable world-anchored Progress Bar. One completed work action removes the top visible segment and its crown, drops exactly one faceted physical Log built with the same tapered geometry as the trunk, and leaves the lower trunk without moving a replacement crown down.
- Palm Trees with a darker slightly bent connected trunk, a two-to-three-World-Unit height, and two irregular five-leaf layers. Palm leaves vary in angle, length, width, curvature, and starting height. Each elongated low-poly leaf has a rounded width profile and increasing downward sag toward the tip rather than forming one symmetric flower shape.
- Human-height cacti that store exactly one `Water` resource each.
- Square limestone formation patches with individual formations from one to three World Units tall.
- Logs and planks that remain physical world objects while loose, reserved, carried, or installed in a building.
- Player orders to gather, move, reserve, build, and reconstruct.
- Simple surfaces, supports, walls, rooms, and spatial storage.
- Construction Sites placed in the world.
- Day/night directional light and a small number of dynamic local lights.
- Event-driven navigation and an early citizen-count stress test.
- A machine-readable observation and command interface.
- Persistent fog-of-war revealed in a four-World-Unit area around every citizen. A right-click whose cursor position is unrevealed always assigns `Walk`, even if its ray intersects a hidden Tree or another collidable entity; revealing the entity on arrival does not convert that existing movement order into work. Its 128×128 mask maps one pixel to each 0.5×0.5 Sub-Unit across the 64×64 prototype world. Stored coverage remains binary. Linear mask interpolation locates a thresholded contour through adjacent Sub-Units, producing straighter diagonals and rounded outer corners without rendering fractional alpha: a fragment is exact fog colour or fully discarded. A hidden one-World-Unit hole is automatically revealed when its four cardinal neighbouring World Units are fully revealed.
- GPU-instanced grass rendered in 8×8 World-Unit chunks, using one upright camera-facing two-triangle billboard per tuft. A hard-cut shader draws four slightly capped blades on each plane and provides per-tuft variation and wind without creating separate blade geometry. Grass never casts a shadow. Scrambled two-dimensional Halton placement plus per-tile permutation, mirroring, axis swap, and shift prevent repeated diagonal rows without sacrificing even coverage. Bushes and grass claim mutually exclusive World Units: whichever greenery type already occupies a unit excludes the other, so grass never renders through a bush. Initial patches spawn fully grown with a maximum height near half the citizen's height. New growth may occur only along existing patch edges.
- Large white block-cloud assemblies visibly moving above the buildable world at approximately height 295, plus a moving cellular cloud-shadow calculation inside the terrain material that is independent of the rotating sun and never stacks darker overlaps. The continuous cloud blobs are sampled against 0.5-World-Unit cells shared with fog-of-war. Estimated coverage above the configurable 50% majority threshold darkens the cell; lower coverage leaves it completely sunlit. Exposed 90-degree boundary corners are clipped into binary quarter circles so the contour follows the rounded fog language without fractional shadow alpha. Cloud shadow uses no coplanar ground overlay and therefore cannot z-fight with sand. Cloud shadow alone is removed inside the reveal area around each Citizen; ordinary terrain, Tree, and Building shadows remain.

Exclude from the first playable version:

- Combat, skeleton enemies, arrows, hunting, bulls, and antelopes.
- Traveler story, alien, aircraft, and vehicles.
- Individual food recipes and named dairy products.
- Thirst, integer health, prisons, and social-conflict simulation.
- Apocalypse and final-ending triggers.
- Full utilities, groundwater, caves, genetics, autonomous outside cities, and dynamic structural failure simulation.

These exclusions reduce the first implementation; they do not prohibit compatible foundations for later expansion.

## 2. Spatial glossary

### 2.1 World Unit

`World Unit` is the standard 1×1×1 construction space.

One World Unit contains exactly:

```text
2 × 2 × 2 Sub-Units = 8 Sub-Units
```

No real-world metre value is assigned yet.

### 2.2 Sub-Unit

`Sub-Unit` is one of the eight equal volumes inside a World Unit. Its edge length is one half of a World Unit.

Sub-Unit coordinates inside a World Unit are integers:

```text
x: 0 or 1
y: 0 or 1
z: 0 or 1
```

Buildings and utilities may occupy one, several, or all eight Sub-Units.

### 2.3 Anchor Node

Each Sub-Unit has six sides. Each side has exactly one `Anchor Node`, positioned at the centre of that side.

```text
one Sub-Unit = six sides = six owned Anchor Nodes
one World Unit = eight Sub-Units = 48 owned Anchor Nodes
```

Two adjacent Sub-Units each retain their own Anchor Node on the shared side. The two opposing Anchor Nodes occupy the same face-centre position and may connect to each other, but they do not become one identity.

```text
48 logical Anchor Node identities
36 distinct face-centre positions inside one isolated World Unit
```

World Units have the same paired relationship at their boundaries. Anchor identity is based on the owning Sub-Unit's global coordinate plus its side direction. Coincident opposing Anchor Nodes form a connection pair.

Anchor Nodes are for solid, face-based attachment and alignment. They are not the path points of a free-hanging electrical cord.

### 2.4 Utility Port and Cord Path Point

`Utility Port` is a functional connection point belonging to a building, tool, or utility device.

`Cord Path Point` is a point belonging only to a flexible free-hanging cord path. A cord can sag or bend through Cord Path Points without creating structural Anchor Nodes.

This keeps structural attachment, functional connection, and flexible cord shape as separate concepts.

## 3. Construction and unrestricted stacking

The placement system does not forbid construction because a space is considered unsupported. Everything may have construction placed above it. The game should preserve player freedom instead of using structural validation as a placement boundary.

Supports, pillars, material strength, sway, and possible future failure may influence appearance or simulation later, but they do not prevent the player from placing a Construction Site.

### 3.1 Surface construction family

`Surface` is one construction family with two forms:

| Form | Walkable | May have construction above | Provides shade |
|---|---:|---:|---:|
| Hard Surface | Yes | Yes | Yes |
| Soft Cover | No by itself | Yes | Yes |

A Hard Surface may act as a floor, road, platform, ceiling, terrace, or roof according to context. Its material may be plank, stone, marble, concrete, or glass.

A Soft Cover may be cloth, hay, or another light material. A pergola is a Soft Cover combined with four corner logs.

### 3.2 Pergola reconstruction

A completed pergola can be reconstructed into a `Support` building:

```text
Pergola = four corner logs + Soft Cover
Support = four corner logs
```

During this reconstruction:

- The Soft Cover material is extracted and returned as a physical resource.
- The four corner logs remain installed.
- Construction already placed above remains in place.
- The resulting Support continues to permit construction above.

Reconstruction should reuse installed components whenever their material and destination remain compatible.

### 3.3 Direct deletion and structural preservation

`Backspace` is the direct removal command for a selected constructed Building, regardless of whether the player or another settlement created it. Naturally generated Trees, Palms, plants, stone formations, and loose resources are excluded: a direct deletion attempt shakes the selected object and leaves it intact, because their normal Citizen work must still be used.

When the selected Building has no construction depending on it from above, it collapses and disappears. When occupied construction above depends on the selected World Unit, removing the lower Building must preserve that upper structure:

- Functional extras of the removed Building disappear, including walls, room enclosure, and its living condition.
- The removed World Unit is replaced by four vertical corner Support poles.
- Construction above remains in place and supported.
- If the replacement cannot be resolved without invalid geometry, deletion is refused and the selected Building shakes.

The present flat Support-only prototype implements direct removal and natural-object refusal. Dependency replacement waits for multi-level occupancy and component data.

### 3.4 Incremental building upgrades

Building upgrades reuse every compatible installed component and request only the missing resources. They create a Construction Site on the existing Building rather than charging for or rebuilding its complete recipe.

The first upgrade chain is:

```text
Support
  + four Planks
  -> Support Platform

Support Platform
  + missing enclosure and roof components
  -> Livable House
```

The Support-to-Platform Construction Site uses the same four short branch assignment handles at the corners of its ground footprint, even when the cube being upgraded is elevated. A Livable House conversion may request hay or finished roof tiles according to the chosen roof recipe; raw clay does not substitute for tiles. Its exact wall and roof quantities must be derived from the final geometry instead of invented in advance.

This upgrade chain is a design contract until Planks, roof resources, component recipes, and multi-level construction are playable.

### 3.5 Free relocation of constructed cubes

Moving an already constructed Building cube is a direct layout operation and requires no Citizen labor:

1. Select the Building.
2. Click and drag it to a destination.
3. While holding it, use `<` and `>` to move the destination one vertical level down or up.
4. Release to place it at the resolved World Unit, including a level that replaces compatible existing structure.

The interaction should feel like arranging physical blocks on a table. Placement collision and replacement rules must be resolved before the drop commits; an invalid drop returns the cube to its origin without consuming resources. This remains deferred until the prototype has vertical Building occupancy.

### 3.6 Selected-building hotkey hints

A selected constructed Building shows a compact hard-pixel tooltip beneath its projected footprint. The rotation hint contains only a clockwise circular-arrow icon and the `R` key. Pressing `R` rotates the Building clockwise by one quarter-turn. `Shift+R` performs the same action counterclockwise, but the modifier is intentionally absent from this immediate hint; advanced players may discover it or inspect it later in configurable controls.

### 3.7 Persistent Edit Mode and deconstruction control

Clicking the top-toolbar Building icon enters Edit Mode and leaves that icon in its filled state. While Edit Mode is active, a Deconstruct button appears immediately to the Building icon's left. It becomes actionable when a completed Building or unfinished Construction Site is selected and invokes the same guarded removal command as `Backspace`. Leaving Edit Mode hides the Deconstruct button, restores the hollow icon, and removes the hidden button's layout space.

## 4. Building appearance system

Building appearance has two independent sources of variation:

1. Player-cycled `Cosmetic Variant`.
2. Contextual vertical appearance such as ground base, middle level, and roof level.

### 4.1 Cosmetic Variant

Every placeable building or tile must provide at least three appearance variants:

```text
Variant 1 → Variant 2 → Variant 3 → Variant 1
```

Placing the same building over a compatible completed building cycles the Cosmetic Variant immediately.

Cycling a completed building:

- Uses no resources.
- Creates no Construction Site.
- Creates no citizen job.
- Has no construction delay.
- Does not change functionality, collision, capacity, occupancy, or connection points.

### 4.2 Permanent Detail Seed

Each built element receives a deterministic `Permanent Detail Seed`. It may adjust safe visual details such as:

- Log bend or rotation.
- Plank spacing and small offsets.
- Wear, colour variation, and minor surface irregularity.
- Idle-motion phase.

The seed does not alter logical geometry. Mesh replacement must be atomic, and generated parts must avoid duplicate coplanar surfaces so cosmetic cycling does not produce z-fighting.

### 4.3 Persistent ground-base appearance

When a building is first completed directly above soil, it receives:

```text
has_ground_base = true
```

This value remains true even if the soil is later excavated or replaced. The building keeps the visual history of having been built at ground level.

Ground-base treatments may include pavement, a plinth, arches, different lower walls, larger or more open windows, or other lower-level details. Every ground-base treatment still supports the three Cosmetic Variants.

### 4.4 Middle and top appearance

Contextual appearance is layered rather than stored as one mutually exclusive building type:

- `Ground Base`: persistent historical treatment assigned at completion.
- `Middle`: used for repeated levels that have construction both below and above.
- `Top`: used for the highest occupied level below an exposed roof.
- `Roof Form`: for example flat or diagonal.

A one-storey building may show both its persistent Ground Base and its Top/Roof treatment. A four-storey building may resolve visually as:

```text
Level 4: Top + Roof Form
Level 3: Middle
Level 2: Middle
Level 1: Ground Base
```

Middle and Top roles may update when construction is added or removed above. `has_ground_base` does not update.

The final visual resolver therefore uses approximately:

```text
building family
+ material
+ has_ground_base
+ current vertical context
+ roof form
+ Cosmetic Variant
+ Permanent Detail Seed
```

### 4.5 Initial colour palette

These are the authoritative starting colours for landscape and early construction. Runtime states may derive lighter or darker versions from them, but individual visual scripts should not substitute unrelated hard-coded colours. Presentation uses binary coverage: a pixel may be fully present or fully absent, never fractionally transparent.

| Use | Hex colour | Code constant |
|---|---|---|
| Wooden roof | `#A85C5C` | `WOODEN_ROOF` |
| Logs used for roofs and early supports | `#E08160` | `ROOF_LOG` |
| Home entrance and doorway | `#7F4645` | `HOME_DOORWAY` |
| Sand surface | `#FEF1CF` | `SAND_SURFACE` |
| Bushes | `#799369` | `BUSHES` |
| Grass | `#93B580` | `GRASS` |
| Hay field | `#FFC471` | `HAY_FIELD` |
| Cactus | `#B1C070` | `CACTUS` |
| Palm trunk | `#8F523E` | `PALM_TRUNK` |
| Palm upper leaves | `#4F713B` | `PALM_LEAF_LIGHT` |
| Palm lower leaves | `#284735` | `PALM_LEAF_DARK` |
| Limestone top | Same current colour as Sand | `LIMESTONE` aliases `SAND_SURFACE` |
| Limestone side reference | `#EEBF8A` | `LIMESTONE_SIDE` |
| Pine wood | `#8B5E45` | `PINE_WOOD` |
| Fog and standard-surface shadow | `#9D9580` | `FOG_AND_SHADOW` |
| Clouds | `#FFFFFF` | `CLOUD` |
| Citizen skin | `#3A1F1F` | `CITIZEN_SKIN` |
| Woman clothing | `#E18074` | `WOMAN_CLOTHING` |
| Metal tools | `#4B7781` | `TOOL_METAL` |
| Hair | `#000000` | `HAIR` |

Bushes, living Tree crowns, and grass use unshaded solid-colour materials, so their green surfaces do not receive smooth lighting gradients. Each living Tree crown or Bush deterministically selects one complete-object colour from the closely related exact-hex `GREENERY_VARIANTS` palette; this adds separation inside dense greenery without runtime randomness or additional save data. Bushes retain geometric cast shadows; grass communicates volume through its silhouette and never casts a shadow.

Sand, greenery, and snow surfaces share `FOG_AND_SHADOW` as the authoritative shadow colour. Fog uses that exact colour as well. Directional soft-shadow filtering is disabled. Standard terrain materials threshold the DirectionalLight attenuation: each fragment resolves to exact surface colour or exact `FOG_AND_SHADOW`, never a feathered or accumulated intermediate. Cloud and world geometry feed the same binary shadow result, so overlapping casters cannot multiply darkness. Living and Dead Tree trunks and loose Logs explicitly cast geometric shadows. Their wood shader thresholds face direction into exactly two colours: `ROOF_LOG` and one derived darker form. Citizens use a separate opaque circular contact disc and do not cast stretched dynamic body shadows; the disc remains circular at morning and evening because it represents contact with the ground rather than the sun's projected direction.

The presentation intentionally uses a low-resolution retro-3D treatment: 3D and screen-space anti-aliasing are disabled, and the completed frame is sampled in hard 2×2 nearest-neighbour pixel blocks. Pixel colours must remain distinct rather than being softened across edges.

### 4.6 In-game Building Constructor

The long-term asset workflow includes an in-game `Building Constructor`; it is not dependent on the player or developer operating an external 3D modelling tool.

- The game begins with authored Building shapes that establish its visual identity.
- A player may later open one of those Buildings and edit its physical composition down to World-Unit and Sub-Unit placement.
- A custom construction can be saved as a reusable prefabricated Building.
- Its recipe is derived from the actual physical parts placed in the constructor. If the design contains seven Logs and five Planks, every constructed instance reserves and consumes exactly seven Logs and five Planks.
- Saving a prefab stores logical parts, transforms, material types, ports, and grouping. It does not flatten the result into an opaque decorative mesh.
- Editing a prefab must preserve the distinction between changing the reusable definition and customizing only one placed instance.

This system is deferred until the basic construction data model supports more than the current Support Construction Site.

## 5. Citizen movement and animation

The first animation states are:

```text
Idle
Walk
Carry
FreeFall
```

Add when stairs enter the playable scope:

```text
StairsUp
StairsDown
```

The initial citizen silhouette has legs occupying approximately half the full body height, with the torso beginning at the hips and the head above it. Each arm has upper-arm and forearm segments joined at an elbow, and each leg has thigh and lower-leg segments joined at a knee. The woman body uses a symmetric guitar silhouette with broad hips, narrow waist, and smaller upper torso; it does not use separate breast meshes. The man body uses an inverted-pear silhouette with shoulders wider than hips. Skin and limbs use solid unshaded `CITIZEN_SKIN`, hair is solid black, men wear yellow shorts, and women wear `WOMAN_CLOTHING` skirts. Future held metal tools use `TOOL_METAL`. Citizens have no default hat; future profession appearance must not leak into the neutral citizen model.

Citizen selection has priority over overlapping world resources. A click selects one citizen, a left-button drag selects every citizen inside the screen rectangle, and empty-ground click deselects all. Every selected Citizen displays an exact two-pixel solid `#FFFFFF` screen-space line projected from a 16-sided horizontal world circle. Its `0.3168`-World-Unit radius is 66% of the previous `0.48` radius. The overlay renders above world geometry so pale terrain, grass, and nearby plants cannot hide it at Town zoom. Selected non-Citizen objects use separate white frames around the top and bottom of their visual bounds; the four vertical connecting bars are intentionally hidden so a tall Tree does not read as a wireframe cage. A group movement order routes every selected Citizen independently into a compact non-overlapping slot inside the same clicked World Unit. Compact lane offsets also separate intermediate route points so Citizens do not deliberately occupy one walking coordinate.

Selecting one or more Citizens enters `Citizen Mode`, parallel to the explicit state used for Building interaction. Citizen Mode remains active while its selection is nonempty and is the context in which right-click movement and work assignments are interpreted. Clearing selection returns to Command Mode, while selecting a Building transfers to Building Mode. The exact future Citizen task menu is deliberately unresolved. One selected Citizen has no numerical badge. For two or more selected Citizens, a red fully rounded badge written conceptually as `(3)` shows the selected count. A one-digit count is exactly 18×18: its horizontal and vertical minimum dimensions are identical, so it cannot become a vertical pill. Multi-digit counts retain the 18-pixel height and circular end caps while expanding only horizontally. The rounded-rectangle badge written conceptually as `[3]` is reserved for goods, building materials, or building quantities and must not be reused as the citizen-selection badge.

The Building icon and `B` key enter or leave persistent Edit Mode and reveal a bottom-centred construction catalog. The catalog uses the same 44×44 icon-button unit as the top toolbar and shows one functional form per building rather than three cosmetic variants. Its initial order is Excavate, Support, Support Platform, Pergola, and Livable House. Unimplemented recipes remain visible but unavailable. Choosing Support begins placement and displays a translucent completed-Support preview snapped to the pointer's valid surface World Unit before the click commits. The current Support Construction Site creates four short faceted wooden assignment stakes beyond its footprint corners immediately on placement. Each stake is planted into the terrain, rises more than 0.3 World Units, and leans farther outward. They use the same trunk colour, hard facets, two-tone wood shader, and shadow behaviour as Trees, loose Logs, and installed Support posts. These stakes remain visible outside Building Mode until construction finishes, so the player can select a citizen and right-click the site to assign that specific citizen. Placement never recruits the nearest citizen automatically. Installed construction remains visible in every mode. Empty-ground click, Escape, or a right-button click without a camera drag leaves Building Mode; holding and dragging the right mouse button rotates the camera instead of cancelling.

Excavate is a landscape-change tool inside the same catalog. Clicking a sand World Unit places an Excavation Site; it does not alter terrain immediately. A selected Citizen must be assigned by right-clicking the marker and completes timed digging before the sand surface disappears. The first implementation creates a shallow pit and removes that cell from surface navigation. Whether removed terrain becomes a carried physical material, a stockpile resource, or no resource remains deliberately undecided, so the current action creates no material output.

With one or more Citizens selected, right-clicking a living Tree, Dead Tree, or Palm assigns tree cutting. Every remaining physical Log segment exposes one independent resumable work slot, so `Tree 3/3` accepts at most three simultaneous Citizens, `Tree 2/3` accepts two, and `Tree 1/3` accepts one. Each assigned Citizen walks to an available neighbouring World Unit, faces the target, produces a low-poly axe from their pocket, and makes exactly three visible chop arcs over three seconds. The slots do not combine their applied seconds into one accelerated job: every completed slot removes one highest remaining segment, creates one loose faceted Log, and reports `Cut 1 log` to that completing Citizen. When the selected group exceeds the clicked Tree’s free slots, remaining Citizens select the nearest visible Trees with free Log segments. Each segment retains target-owned interruption and resume state. Simultaneous slot bars are vertically offset rather than occupying the same pixels. The applied-labour bar is eight pixels high: a four-pixel coloured interior plus a two-pixel white outline above and below matching the custom cursor. It fills horizontally from left to right and uses small rounded corners rather than a sharp rectangle. The coloured fill is confined to the inner rectangle and the white outline is drawn last, so even completed labour cannot cover the border. The entire bar pivots around its centre and leans by at most two degrees toward the screen side occupied by the directional sun; its lean reverses as the sun moves to the opposite side. Its width is eight pixels per required simulation second, so a three-second job is 24 pixels wide and a six-second job is 48 pixels wide. A three-segment Tree advances through `Tree 3/3`, `Tree 2/3`, and `Tree 1/3`; only the third completed slot replaces the final segment with the short rooted stump. Removing the original top also removes its crown, branches, or Palm leaves without generating replacement top geometry on the lower trunk. Harvested lower trunks do not resume normal growth. Each drop direction is deterministic and selects the Log's cardinal axis; continuous falling-body physics is deferred.

Bushes and cacti use the same assignment contract instead of resolving immediately on arrival. The Citizen works beside the target for three seconds while the shared applied-labour bar fills. Applied labour belongs to the target and work kind rather than to the actor or tool: interruption preserves the accumulated seconds, keeps the bar visible for two simulation seconds, then hides it until any actor resumes the same job from its remaining time. A completed bush harvest immediately adds one `Calories` in the current inventory-free slice, hides every red berry dot while retaining the green bush, and starts a two-game-day regrowth timer. With the current 360-second Day, berry regrowth takes exactly 720 real seconds; expiry restores the same deterministic berry arrangement. A completed cactus collection adds its stored `Water` and removes the depleted cactus. Separating collected food from eating is deferred until a physical food or inventory system exists.

Every traversable surface World Unit exposes eight movement neighbours: north, north-east, east, south-east, south, south-west, west, and north-west. When both target coordinates differ, the route uses a direct diagonal centre-to-centre step instead of alternating cardinal steps into a ladder pattern.

The current navigation service marks limestone, living and dead Trees, Palm Trees, cacti, and bushes as solid World Units. A path is requested only when an order changes. Work orders choose a reachable neighbouring World Unit instead of walking through their solid target. Diagonal movement is rejected when it would cut between two blocking corners. The deliberate outside-world edge attempt remains a separate bounded exception.

The Town Mode camera begins centred on the first citizen but is independent after that point. Its default orthographic view is twice as far out as the original close view, while mouse-wheel zoom can still return to that original framing as the maximum zoom-in level. WASD pans it across the playable area at a speed proportional to the current zoom; selection and movement do not force the camera to follow a citizen. Holding and dragging the right mouse button horizontally rotates it through 360 degrees. Vertical right-button drag changes elevation by at most ten degrees above or below the default isometric elevation, never near enough to become parallel with the ground. The bottom-right compass remains physically parallel to the ground and renders at a 72-pixel diameter. Its darker cylindrical side wall is three times the earlier height, and the `WOMAN_CLOTHING` North and `TOOL_METAL` South triangles sit substantially below the raised rim. Its 50%-transparent white sun reflection spans the compass diameter, widens toward roughly one third of the face near morning and evening, and narrows near midday. Hover or keyboard focus uses the current 3D viewing direction and surface normals to generate a fixed-width white silhouette; it must not substitute a circular 2D border. Clicking the compass resets the camera to the default yaw and elevation. Normal depth testing, rather than a manual z-index override, determines whether a tree or Building is in front from the current view.

One Day lasts 360 real seconds in the current prototype. The sun travels from the eastern horizon through overhead noon to the western horizon, then below the world for the night half. A top-centred rotating wheel has a yellow Day half, an empty Night half with no moon, and a fixed sun marker above it. The Day counter increments after every complete cycle. Morning gradually changes from light blue to the yellowish Day palette. Evening gradually changes from the Day palette through red to the blue Night palette. Sun energy, sky, fog, terrain, and shadow colours interpolate through these stages instead of changing at one horizon frame.

Limestone remains visually related to its surrounding sand: it is a slightly darker pale sand colour by Day and follows the active terrain hue into blue-gray at Night. A restrained night emission floor preserves its form when direct sun is absent without making it appear self-luminous.

The finite prototype has no visible collision-wall geometry. The flat presentation sand continues beyond the logical world and remains clickable. A movement order may target one route node beyond the logical edge so the citizen visibly attempts the requested movement, but its physical position stops at the actual world boundary.

Each locomotion animation stores its reference speed and stride length. Animation playback derives from actual path movement so an animated step covers approximately the same world distance every time.

Citizens may traverse most natural terrain. Traversal normally changes cost rather than acting as a binary prohibition:

- Flat ground: normal speed.
- Moderate slope: slower.
- Shallow water or irrigation channel: passable but slower.
- Loose soil: slower.
- Enormous or near-vertical cliff: blocked.
- Missing supporting surface: FreeFall.

Stairs and bridges improve movement but are not mandatory for every small elevation or shallow channel.

### 5.1 Deferred elevators and crowd movement

An `Elevator` is a later Building and is not part of the first playable scope. An Elevator requires an `Elevator Shaft` that occupies one World Unit in width and depth and spans at least two World Units vertically. The minimum useful Elevator connects the first and second Floors; a taller Elevator may connect additional Floors.

Elevator routing is based on estimated arrival time rather than vertical distance alone. A Citizen may keep walking or use nearby stairs or a ladder when that route is expected to arrive sooner. A Citizen may instead use an Elevator when walking to another vertical route would take longer. The estimate must include walking to the Elevator, waiting for the Elevator Car, riding, and walking from the destination Floor. Route planning must not assume that entering an Elevator is instantaneous.

Using an Elevator requires explicit simulation state:

1. A Citizen walks to the call position for the current Floor.
2. The Citizen requests the Elevator and waits if the Elevator Car is elsewhere.
3. The Elevator Car arrives if it can accept the request.
4. The Citizen boards when capacity is available.
5. The Elevator Car travels to the requested Floor and the Citizen exits.

The standard one-World-Unit Elevator Car has a provisional capacity of four Citizens, corresponding to four standing Sub-Unit positions across its floor. When the Elevator Car is full, it does not stop merely to collect more waiting Citizens. A full Elevator must still complete the destination stops requested by Citizens already inside it. Waiting Citizens retain their request for later service. Scheduling details beyond these rules remain deferred until the Elevator is prototyped and stress-tested.

Citizen bodies do not form permanent navigation obstacles for one another. Citizens may temporarily pass through or occupy the same Sub-Unit so a dense crowd cannot deadlock pathfinding or overwhelm the navigation service. If many idle Citizens occupy the same destination, a low-frequency crowd-settling process gradually moves them into comfortable nearby free Sub-Units. This makes even an accidental stack of 100 Citizens recover by spreading over time rather than requiring 100 simultaneous collision-driven path calculations.

A group movement order places every selected Citizen inside the one clicked destination World Unit, using compact distinct surface slots so they do not finish on one identical point. Every Citizen receives an independent A* route from its own current position. The command does not preserve the starting formation as parallel destination World-Unit offsets. Temporary overlap remains an emergency safeguard, not the normal result of a group order.

Horizontal moving carts may later reuse parts of the stop, capacity, queue, and boarding model. They remain an alternative transport direction rather than a committed Building family.

## 6. LLM observation and control interface

The LLM does not require a continuous 3D video feed. Its authoritative view is structured text data.

### 6.1 Observation rate

Default LLM observation rate:

```text
0.5 observations per second = one observation package every 2 real seconds
```

This rate is independent of rendering FPS and simulation tick rate. An automated test may instead pause the simulation and advance an explicit number of ticks after each command.

Each observation package contains either:

- A requested regional or layered snapshot.
- A delta since the previous acknowledged observation.
- Recent events and command results.

Periodic checksums and full snapshots allow the client to recover if it misses a delta.

### 6.2 Required readable state

The interface must expose stable Entity IDs and sufficient information to reason about:

- Terrain, cliffs, slopes, caves, and empty space.
- World Unit and Sub-Unit occupancy.
- Buildings, Construction Sites, materials, and completion state.
- Citizens, current actions, carried resources, and destinations.
- Loose and reserved physical resources.
- Anchor Nodes, Utility Ports, ladders, supports, doors, and routes.
- Utility networks when those systems are implemented.

Cells reference Entity IDs; entity details are stored once rather than copied into every cell.

### 6.3 Required command input

The first command vocabulary should support:

```text
query_region
query_layer
query_entity
query_route
place_construction_site
place_ladder
place_support
connect_buildings
cancel_construction_site
set_job_priority
advance_ticks
```

A placement command needs explicit coordinates and orientation. A high-level command may request a result, but the LLM must be able to inspect the proposed plan before confirming it.

Example shape:

```json
{
  "command": "place_construction_site",
  "building_type": "support.basic.wood",
  "origin_world_unit": [12, 4, -8],
  "occupied_sub_units": [[0, 0, 0], [0, 1, 0]],
  "rotation_quarters": 1,
  "cosmetic_variant": 2
}
```

The interface is also the foundation for automated QA, headless stress tests, and later autonomous outside settlements.

## 7. Utility capacity and visual scaling

`Capacity Grade` is written as 1×, 2×, 3×, or 4×. It describes how much service a utility segment or device can carry or provide. It does not always mean that the visible object becomes two, three, or four times wider.

Each utility family defines its own allowed grades and visual growth rule:

| Utility family | Allowed grades | Visual growth | Colour |
|---|---|---|---|
| Flexible electrical or signal cord | 1×, 2×, 3×, 4× | Remains thin; higher grades become only slightly thicker | Black |
| Cold-air ventilation duct | 1×, 2×, 4× | Cross-section grows substantially; 2× is rectangular and 4× may fill one Sub-Unit | Silver metallic |
| Natural-gas pipe | 1×, 2×, 3×, 4× | Circular diameter grows with grade | Yellow |
| Water pipe | 1×, 2×, 3×, 4× | Circular diameter grows with grade | Not assigned yet |
| Drainage pipe | 1×, 2×, 3×, 4× | Circular diameter grows with grade | Blue |

The Black Cord is a line or small bundle, not a large pipe. A 2× Black Cord occupies almost the same space as a 1× cord, with only enough extra thickness to communicate its greater capacity. A 3× or 4× cord continues the same restrained growth instead of expanding like a ventilation duct.

Ventilation intentionally skips 3× because filling three quarters of a square cross-section produces an unwanted L-shaped form. Its visual progression is:

```text
1× small duct → 2× rectangular duct → 4× full square duct
```

Gas, water, and drainage use continuously larger circular diameters. Their visual diameter curve is configurable and need not follow a physically exact area calculation, but each grade must remain recognisable.

Flexible Black Cords use Utility Ports and Cord Path Points. They do not consume or create structural Anchor Nodes merely because they sag through free space.

### 7.1 Satellite dish

The `Satellite Dish` is a later Utility device for televisions. It may mount on a wall or roof.

```text
1× Satellite Dish = capacity for 1 television
2× Satellite Dish = capacity for 2 televisions
4× Satellite Dish = capacity for 4 televisions
```

Each connected television consumes one unit of dish capacity. The larger dish variants may visibly grow, but their mount and cable connections remain separate Utility Ports.

The Satellite Dish is recorded for future compatibility and is not part of the first playable scope.

### 7.2 Connection state without persistent panels

Copied flats and prefabricated Buildings must communicate missing Utility connections in the world itself. The game should not require a persistent needs panel for every room.

Shared rules:

- A connected, actively working Utility is visually `Alive`: its expected motion runs and its material uses the normal bright colour.
- A disconnected or unpowered Utility is visually quieter and darker.
- Hover text names the missing input, such as `Missing electricity` or `Missing cold air`, but the physical cue remains understandable without hovering.
- Diagnostic effects occur at restrained intervals. A fault must not resemble a fully working continuous flow.
- Copying a flat preserves its required Utility Ports. At the destination, only unsatisfied ports display their local connection request.

Family-specific cues:

| Utility | Working cue | Missing or disconnected cue |
|---|---|---|
| Cold-air outlet | A small paper strip lifts and streams in the outlet airflow | The strip hangs flat with only occasional subtle ambient movement comparable to grass |
| Water pipe | Normal contained motion at an active device | A restrained water droplet at the open or missing connection point |
| Electricity | Powered tools are brighter and visibly active | An occasional short zap at the unsatisfied electrical connection, never a continuous working effect |
| Fridge, AC, and other machines | Bright normal colour plus device-specific vibration or motion | Darkened material, reduced motion, and hover text naming the missing Utility |

The paper strip, droplet, and zap are presentation components driven by one authoritative connection state. They must not implement their own connection logic.

### 7.3 Minimal global controls

The normal game view uses no opaque top navigation background. A Population indicator occupies the top-left corner, while compact controls occupy the top-right. Design terminology remains precise in this specification, while player-facing labels use the shorter text recorded in the UI text catalog:

- A black Citizen silhouette followed by a number reports the total simulated Population. The icon uses the player-facing tooltip `Population`; it is distinct from the selected-Citizen badge.
- A text control cycles simulation speed through `1×`, `2×`, and `4×` and uses the player-facing tooltip `Simulation speed`.
- A hollow five-edge Building icon toggles Building Mode and uses the player-facing tooltip `Build`. Its black contour alone uses an exact two-pixel solid stroke. Its two roof edges slightly overhang the two vertical walls, its bottom closes the silhouette, and it has no horizontal ceiling edge. Hover and keyboard focus add the shared white outline; active Building Mode fills the silhouette black.
- A cross-shaped Save-and-Quit control uses the player-facing tooltip `Quit`. The Save-and-Quit control is disabled until resumable save/load exists and must never silently discard a playthrough.

Simulation speed scales authoritative world time, Citizen movement, labour progress, plant regrowth, and environmental motion. Camera input, hover delays, onboarding, and speech-message visibility continue at real UI time. Durations are floating-point simulation seconds and have no divisibility requirement: a three-second job is still exact at every speed, taking 1.5 real seconds at `2×` and 0.75 real seconds at `4×`.

The Save-and-Quit cross has a solid black interior made from two slightly unequal rounded strokes, giving it a hand-drawn form. It has no white resting outline; hover or keyboard focus adds the shared white stroke. Every top-toolbar button reserves a complete rectangular hit area independently of its icon's opaque pixels. Its square tooltip is anchored beneath that rectangle and must never cover the icon. The custom cursor is a friendly rounded arrow with a solid black interior and solid white outline and defines the application-wide outline-width standard. The fixed sun marker uses this same border width, while the larger Day/Night wheel retains the visually equivalent black perimeter. These controls contain no antialiasing or semi-transparent edge pixels. World-object names appear as plain black text above the scene after a short stable hover, without a dark tooltip panel. Native control tooltips use square black panels with hard white borders and no smooth corner radius. UI text retains the earlier vector fallback font source but rasterizes it at four times the previous density while disabling font antialiasing, subpixel positioning, and filtered glyph sampling. Selecting a non-Citizen world object draws a complete 12-edge white outline around its visible bounds; it does not use isolated corner marks. Selecting revealed ground draws one continuous four-edge rectangle around only the chosen World Unit’s top surface. Selection thickness is recalculated from camera distance to preserve the shared cursor-width appearance. Citizen selection instead uses its white contact-shadow perimeter. Normal hover content names only the hovered entity or surface. Development-only values such as entity ID, coordinates, seed, state, and capacity belong to a separately toggled debug layer and must not leak into the default tooltip.

The general shape-language rule is to avoid very sharp exposed edges. Terrain, buildings, vegetation, citizens, controls, and other world objects use softened, rounded, faceted, or slightly irregular corners appropriate to their material. Tools held by citizens are the deliberate exception: their working edges may remain visibly sharp.

The selected-citizen count is an 18×18 circle attached beside the cursor rather than a fixed screen-corner panel, and it appears only for groups of two or more. Multiple digits may widen this badge but cannot increase its height. The movement preview reads as `O-------●`: the Citizen's exact two-pixel selection circle, one continuous two-pixel exact-white screen-space polyline projected from the remaining world route, and one larger destination dot. Intermediate pathfinding nodes have no circular markers. The first segment follows the moving Citizen. A single joined projected line prevents diagonal movement from breaking into dashed depth-rendered patches under the nearest-pixel pass. A movement target that is blocked, disconnected, unknown, or beyond the current prototype boundary resolves to the closest reachable World Unit instead of producing a no-result order.

### 7.4 Actor speech bubbles and message bus

Citizens and future world actors communicate immediate intent or an unresolved condition through one shared `Actor Message Bus`. Actors submit a semantic message ID; they do not construct or position UI themselves. The message catalog defines the icon, optional very short text, priority, initial delay, visible duration, queue lifetime, repeat interval, maximum repeat interval, and whether identical messages may cluster. This is notification infrastructure, not a hard-coded desire or dialogue simulation.

The normal Citizen bubble is a compact, approximately half-original-scale, fully opaque white, black-outlined 2D card with black text and a code-drawn icon. A Building or separate Utility element uses the same bubble geometry with a fully opaque gray background and black text, allowing the player to distinguish a Citizen need or confirmation from equipment asking for a connection. The actor category comes from the speaker rather than from the message: Citizens identify themselves explicitly, while generic non-Citizen world actors default to the Utility treatment. The bubble is projected above its actor's head and always faces the player. It ignores pointer input and is drawn above ordinary world geometry, but it is hidden when the actor is outside the camera view, behind the camera, or occluded from the camera by solid terrain, Limestone, a Tree, or a Building. Another small speaking actor does not count as a solid occluder.

Visible bubbles are screen-space packed with an eight-pixel gap. When their desired rectangles overlap, later bubbles move upward until they are separate. A maximum of three message groups may be visible at once. Queue ordering is priority-first and then oldest-first. Pending messages have a time-to-live and are discarded if they become stale before they can be shown.

Identical clusterable conditions use a caller-supplied scope such as a Room, Building, or Utility network. Twelve citizens in one Room asking for Water therefore produce one Water icon with `×12`, not twelve simultaneous bubbles. Each later reminder advances to another still-affected actor. The initial persistent-need timing is two seconds before display, four seconds visible, and eight seconds before the first reminder. Continued reminders back off to 16, 32, and at most 64 seconds. A simulation system must refresh a condition while it remains true; if refresh stops because the condition was solved, its message expires without separate UI cleanup.

Work-order confirmations use a separate one-shot profile: nearly immediate appearance, approximately two seconds visible, no repetition, and a short queue lifetime. Implemented confirmations are a Log for cutting or gathering Wood, three red circles with no green stems for Food, a Water drop for Cactus collection, and a hammer for construction. Movement deliberately has no speech bubble; the selected Citizen's outlined contact shadow and route preview confirm the movement order. A Plank icon and message definition are prepared for the later Plank task without implementing that resource chain yet. This lets the player verify which work order was understood without reading a sentence. Rare literal speech may use a very short localized phrase such as `OK`, `Bye`, or `Yay`, but icons remain the default.

The bus accepts any `Node3D` with a speech anchor, so Buildings and Utilities can later report a missing connection through the same queue, clustering, priority, expiry, and occlusion rules. Prepared persistent message definitions include Water, Food, excessive heat, fresh air, and disconnected Utility. Those definitions do not create needs by themselves; their owning simulations must decide when the condition exists.

### 7.5 First-launch learning mode and Building hotkeys

On the first installation, a short learning overlay shows a semi-transparent keyboard silhouette and highlights only the keys used by the current lesson. Completion is stored locally; `F1` reopens the lesson. The first implemented lesson highlights `W`, `A`, `S`, and `D` for camera movement and closes as soon as one is used or the player selects `Got it`.

Building interaction contract:

| Input | Result |
|---|---|
| Building icon or `B` | Open or close the building menu without selecting a Building type |
| Support icon | Select Support placement and close the building menu |
| `Alt` + left click | Select the exact collider under the cursor, bypassing higher-priority grouped or citizen selection |
| Selected Building type + left click | Place one Construction Site, then close that Building-type placement selection |
| Selected Building type + `Ctrl` + left click | Place one Construction Site and keep that Building type active for another copy |
| Selected citizen + right-click Support site | Assign that citizen to fetch Logs and construct that site |
| Selected Citizen group + right-click Tree | Fill that Tree’s remaining Log work slots, then assign overflow Citizens to the nearest visible Trees with free segments |
| Draggable Building family + left drag | Fill the crossed World Units with the selected Road, Bridge, or Fence family according to that family's stretch rules |
| `]` | Move selection to the containing upper group |
| `[` | Return through selection history toward the previously selected smaller child |

Grouping follows the Figma-like layer model. A hierarchy may be `Building → Level → Flat → Room`, but missing groups are not invented; a correctly authored Building may legitimately jump directly from `Building` to `Room`. Draggable families and bracket navigation are activated only after those construction families and persistent group identities exist.

### 7.6 Player-facing text catalog

Design terminology and player-facing language are separate layers. Design documentation and code may use a precise term such as `Construction Site`, while the ordinary world tooltip may display the shorter noun `Support`. Player-facing object labels should normally use one short noun. Player-facing action labels should normally use one short verb.

Every player-facing string uses a stable text key containing at least two underscore-separated words. The authoritative table is `localization/ui_text.csv`. The table follows Godot's native localization CSV structure and stores planning metadata in underscore-prefixed columns that Godot ignores during translation import.

Every catalog row records a planned character limit. The English text is validated when the catalog loads, and formatted runtime text is checked again after dynamic values are inserted. A later UI verification pass must also measure rendered glyph width because equal character counts do not guarantee equal pixel widths across languages or fonts.

## 8. Simulation and rendering boundary

Godot is the engine and presentation layer. The authoritative simulation must not be encoded only in scene-tree nodes.

Keep these concepts separate:

- Simulation: IDs, coordinates, occupancy, resources, jobs, paths, reservations, and construction state.
- Presentation: meshes, animation, lights, shadows, particles, sound, and selection visuals.
- Interface: player commands and the LLM snapshot/delta protocol.

Important rules:

- Do not calculate a complete A* path for every citizen on every rendered frame.
- Request paths when a job or destination changes or a route becomes invalid.
- Run simulation at a lower fixed rate and interpolate visible movement.
- Batch repeated geometry and rebuild only affected chunks.
- Visual idle motion must not continuously invalidate collision or navigation.
- Optimise only after repeatable profiling identifies a bottleneck.

### 8.1 Persistence contract for generated detail

Generated visual detail is split by gameplay significance:

- Individual grass blade and tuft transforms are presentation-only. Do not serialize them. Rebuild them from patch occupancy and runtime variation rules when a world loads.
- Every tree, Palm Tree, cactus, stone formation, loose log, reserved log, carried log, and installed construction log has persistent identity. Save its `Permanent Detail Seed` or its resolved transform so reloading does not visibly move or rotate it.
- Tree and Palm Tree segment count, inherited bend, resource state, and origin material are persistent simulation data.
- Citizen body traits are persistent citizen data and later form part of the genetic appearance system; they must not be rerolled on load.

The save format should prefer a compact seed where the generation algorithm is stable. If changing that algorithm could move an existing important object, store the resolved transform or preserve a generator-version field.

### 8.2 Canonical Cloth resource

`Cloth` is one source-agnostic crafting resource. Construction and downstream manufacturing consume `Cloth`, not separate cotton-cloth, linen-cloth, or wool-cloth item types.

Its upstream source depends on biome:

| Biome / difficulty | Source | Acquisition direction |
|---|---|---|
| Greenery / easy | Cotton | Grow and collect |
| Sand / normal | Linen | Grow and collect |
| Snow / hard | Wool | Sheep grows wool; collect it at a cutting station |

Source provenance may remain metadata for visuals or trade, but it must not multiply otherwise identical downstream recipes.

## 9. First code milestone

The first Godot milestone should implement no finished game art. It should prove the data model with coloured primitives.

Acceptance checks:

1. A World Unit reports exactly eight Sub-Units.
2. Each Sub-Unit exposes one Anchor Node per side.
3. Shared faces expose two coincident, opposing Anchor Nodes that can form a connection pair.
4. A free-hanging cord uses Cord Path Points, not Anchor Nodes.
5. A Construction Site may be placed above any occupied construction.
6. Pergola-to-Support reconstruction returns its Soft Cover resource without deleting construction above.
7. Cosmetic cycling changes a completed mesh immediately without creating a job.
8. A ground-base appearance remains after the soil below is removed.
9. Four stacked buildings resolve to base, middle, middle, and top visual contexts.
10. An LLM client can receive a snapshot, place a Construction Site by coordinates, advance ticks, and receive the resulting delta.
11. Citizens request paths only when necessary rather than once per rendered frame.

The first implementation files can follow this boundary:

```text
simulation/spatial/world_unit.gd
simulation/spatial/anchor_registry.gd
simulation/entities/entity_store.gd
simulation/construction/construction_service.gd
simulation/navigation/navigation_service.gd
presentation/buildings/building_visual_resolver.gd
interface/commands/command_service.gd
interface/observation/observation_service.gd
tests/
```

Names may change after the Godot project skeleton exists, but the boundaries should remain.

## 10. Deferred design notes

Keep these visible without implementing them in the first milestone:

### 10.1 Nomadic playthrough direction

A later playthrough may begin with two citizens travelling away from the standard starting area. They craft two pairs of boots, gather resources while moving, and carry progression mainly as knowledge instead of hauling a permanent stockpile of construction materials. The group may settle for several cycles to build temporary research facilities and grow its family, then continue the journey. World goals should encourage exploration and relocation rather than requiring every playthrough to become a permanent settlement.

- Logical voxel terrain with smoothed hills, rounded exposed soil corners, and preserved vertical cliffs.
- Loose soil settling at approximately 45 degrees.
- Four Loose Soil World Units compressed into one stable Compacted Earth World Unit.
- Saturated solid soil that seeps into newly excavated empty cells.
- Two snapped camera modes: Town Mode and Sub-Unit Detail Mode.
- All Buildings may have harmless visual Idle Motion; AC units vibrate more strongly and tall buildings may sway slightly.
- Dynamic sun, fire, and selected artificial lights cast real-time shadows without pre-baked shadow maps.
- Caves, autonomous outside cities, family genetics, ageing, services, utilities, fire, and large marble construction projects.
- Snow terrain uses denser tree availability than the sand prototype. Its Pine Tree produces visually distinct `PINE_WOOD` logs. Log material and biome of origin remain attached to the physical resource, so pine logs may be transported and used in a desert settlement.
- The first snowy dwelling is a full log cabin rather than the light eight-log/four-plank building concept. Its provisional budget is approximately 16 logs; the exact count must be derived from the final cabin geometry before becoming a recipe.
- Cotton, linen, and wool production are deferred, but all three must resolve to the canonical `Cloth` resource defined in section 8.2.
- Elevator Buildings, Elevator Shafts, multi-Floor route-time comparison, call queues, four-Citizen Car capacity, and crowd-settling behavior follow section 5.1 and remain deferred until multi-level navigation exists.

## 11. Sound design asset backlog

The game needs original audio assets for these initial sound events. The names below are provisional event identifiers rather than filenames or implementation details.

### System

- `clicking_a_menu_button_sound`: play when the player clicks a menu button.

### Notification

- `starting_new_day_sound`: play when a new Day begins.

### Action

- `chop_tree_sample_1_sound`
- `chop_tree_sample_2_sound`
- `chop_tree_sample_3_sound`

The three Tree-chopping samples provide variation for repeated chopping actions.

### Surrounding

- `cricket_sound`: enable during the evening.
- `frog_sound`: eligible to play while a Water resource is nearby; consecutive plays must be at least four seconds apart.

### Soundtrack

- `soundtrack_1_audio`: first soundtrack asset.
