# Building Blueprint Format

Status: Version 2 implementation, subordinate to `scripts/building_blueprint.gd` and its tests.

The Building Constructor saves human-readable `.pyrbuilding` JSON. A blueprint remains a collection of logical physical parts; it is never flattened into one decorative mesh. Version 2 is the authoritative game asset, recipe, and interchange source. Blender-compatible OBJ files are generated from it rather than maintained as a second model.

## Version 2 scope

- Bounds are positive whole `World Unit` dimensions. Support, Platform, and Sawmill are `1×1×1`; Pile is `2×1×2`.
- Every World Unit contains the canonical eight `Sub-Units` (`2×2×2`).
- Multiple logical parts may share a Sub-Unit when a structure such as the ten-Log Sawmill needs it. IDs remain unique.
- Supported part kinds are `Block`, `Log`, and `Plank`.
- Supported orientations are `x`, `y`, and `z`.
- Supported materials are Wood, Limestone, Marble, and Concrete.
- Decorative parts consume no construction resource. This is how the Pile's four marker stones remain free.
- A recipe may be derived from physical parts or explicitly declared.
- Workshop recipes store physical inputs, outputs, and work seconds. Sawmill encodes `1 Log → 1 Plank` in `3` seconds.
- `visual_variant` is `0`, `1`, or `2` and changes appearance without changing function or recipe.

Every part stores its identity, kind, material, source resource, Sub-Unit address, orientation, visual variant, and explicit geometry. Logs store start/end points and radii. Blocks and Planks store centre, size, and rotation. Explicit geometry lets later constructor tools add endpoint dragging, diagonal parts, and overhangs without changing the basic file model.

For derived recipes, each non-decorative part contributes one resource and its stored `resource` must match its kind and material. The included [Four Log Support](data/buildings/four_log_support.pyrbuilding) therefore produces `{ "log": 4 }`, while [Platform](data/buildings/platform.pyrbuilding) produces `{ "log": 4, "plank": 4 }`.

## Blender export

Run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --rendering-driver dummy --path . --script tools/export_official_building_assets.gd
```

The generated OBJ files are under `data/buildings/exports/`. Blender imports them with **File → Import → Wavefront (.obj)**. One OBJ unit equals one Pyramida World Unit and one Blender metre. Object names and comments preserve part IDs, resource kinds, and Sub-Unit addresses.

## Development workflow

1. Run the main game and press `F2` to enter the Building Constructor.
2. Left-click one of the eight Sub-Units to place or replace the active part. Right-click removes it.
3. Use `1`, `2`, and `3` for Block, Log, and Plank; `M` changes material; `R` changes axis; `V` changes the visual variant; `Y` switches between the lower and upper four Sub-Units.
4. `Tab` switches between gray edit mode and the actual material preview.
5. `Ctrl+S` saves to `user://blueprints/developer_world_unit.pyrbuilding`. `Ctrl+Shift+S` opens Save As, and `Ctrl+O` imports an existing `.pyrbuilding` file.
6. An approved file may be placed under `res://data/buildings/`, added to the official export list, and shipped as an official prefab plus generated OBJ.

Runtime construction, previews, completed models, recipes, and OBJ export all load the same file through `BuildingBlueprint.load_from_file(path)`. No parallel prefab format should be introduced.
