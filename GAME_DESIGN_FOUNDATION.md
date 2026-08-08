# Pyramida 2 — Foundation Specification

Status: living, editable specification for the first clean-room prototype.

This document records agreed terminology and rules. It is deliberately smaller than a complete game-design document. The first implementation should prove the peaceful gathering, carrying, construction, navigation, and visual-building loop before the deferred systems are added.

## 1. First playable scope

The first playable version is a peaceful, vegetarian construction sandbox inspired by the basic loop of Sokpop's *Pyramida*, with original code and assets.

Include first:

- Citizens with `Idle`, `Walk`, `Carry`, and `FreeFall` states.
- Renewable bushes or wild crops that produce a single `Calories` resource.
- Trees that can be planted and cut into physical logs.
- Logs and planks that remain physical world objects while loose, reserved, carried, or installed in a building.
- Player orders to gather, move, reserve, build, and reconstruct.
- Simple surfaces, supports, walls, rooms, and spatial storage.
- Blueprint plans placed in the world.
- Day/night directional light and a small number of dynamic local lights.
- Event-driven navigation and an early citizen-count stress test.
- A machine-readable observation and command interface.

Exclude from the first playable version:

- Combat, skeleton enemies, arrows, hunting, bulls, and antelopes.
- Traveler story, alien, aircraft, and vehicles.
- Individual food recipes and named dairy products.
- Thirst, integer health, prisons, and social-conflict simulation.
- Apocalypse and final-ending triggers.
- Full utilities, groundwater, caves, genetics, autonomous outside cities, and structural destruction.

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

Supports, pillars, material strength, sway, and possible future failure may influence appearance or simulation later, but they do not prevent the player from placing a Blueprint.

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
- Creates no Blueprint.
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

Each locomotion animation stores its reference speed and stride length. Animation playback derives from actual path movement so an animated step covers approximately the same world distance every time.

Citizens may traverse most natural terrain. Traversal normally changes cost rather than acting as a binary prohibition:

- Flat ground: normal speed.
- Moderate slope: slower.
- Shallow water or irrigation channel: passable but slower.
- Loose soil: slower.
- Enormous or near-vertical cliff: blocked.
- Missing supporting surface: FreeFall.

Stairs and bridges improve movement but are not mandatory for every small elevation or shallow channel.

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
- Buildings, Blueprint plans, materials, and completion state.
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
place_blueprint
place_ladder
place_support
connect_buildings
cancel_blueprint
set_job_priority
advance_ticks
```

A placement command needs explicit coordinates and orientation. A high-level command may request a result, but the LLM must be able to inspect the proposed plan before confirming it.

Example shape:

```json
{
  "command": "place_blueprint",
  "blueprint": "support.basic.wood",
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

## 9. First code milestone

The first Godot milestone should implement no finished game art. It should prove the data model with coloured primitives.

Acceptance checks:

1. A World Unit reports exactly eight Sub-Units.
2. Each Sub-Unit exposes one Anchor Node per side.
3. Shared faces expose two coincident, opposing Anchor Nodes that can form a connection pair.
4. A free-hanging cord uses Cord Path Points, not Anchor Nodes.
5. A Blueprint may be placed above any occupied construction.
6. Pergola-to-Support reconstruction returns its Soft Cover resource without deleting construction above.
7. Cosmetic cycling changes a completed mesh immediately without creating a job.
8. A ground-base appearance remains after the soil below is removed.
9. Four stacked buildings resolve to base, middle, middle, and top visual contexts.
10. An LLM client can receive a snapshot, place a Blueprint by coordinates, advance ticks, and receive the resulting delta.
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

- Logical voxel terrain with smoothed hills, rounded exposed soil corners, and preserved vertical cliffs.
- Loose soil settling at approximately 45 degrees.
- Four Loose Soil World Units compressed into one stable Compacted Earth World Unit.
- Saturated solid soil that seeps into newly excavated empty cells.
- Two snapped camera modes: Town Mode and Sub-Unit Detail Mode.
- All Buildings may have harmless visual Idle Motion; AC units vibrate more strongly and tall buildings may sway slightly.
- Dynamic sun, fire, and selected artificial lights cast real-time shadows without pre-baked shadow maps.
- Caves, autonomous outside cities, family genetics, ageing, services, utilities, fire, and large marble Blueprint projects.
