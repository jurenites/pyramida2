# Building Blueprint Format

Status: experimental implementation, subordinate to `scripts/building_blueprint.gd` and its tests.

The Building Constructor saves human-readable `.pyrbuilding` JSON. A blueprint remains a collection of logical physical parts; it is never flattened into one decorative mesh. The current JSON round-trip test reports a logical-part type mismatch, so Version 1 must not yet be treated as a stable interchange format.

## Version 1 scope

- Bounds are exactly one `World Unit` (`1×1×1`).
- The editable volume contains the canonical eight `Sub-Units` (`2×2×2`).
- One editable part may occupy each Sub-Unit.
- Supported part kinds are `Block`, `Log`, and `Plank`.
- Supported orientations are `x`, `y`, and `z`.
- Supported materials are Wood, Limestone, Marble, and Concrete.
- `visual_variant` is `0`, `1`, or `2` and changes appearance without changing function or recipe.

Every part stores its identity, kind, material, source resource, Sub-Unit address, orientation, visual variant, and explicit geometry. Logs store start/end points and radii. Blocks and Planks store centre, size, and rotation. Explicit geometry lets later constructor tools add endpoint dragging, diagonal parts, and overhangs without changing the basic file model.

The recipe is derived from each part's kind and material; the stored `resource` must match that mapping and is validated during import. The included [Four Log Support](data/buildings/four_log_support.pyrbuilding) therefore produces `{ "log": 4 }`.

## Development workflow

1. Run the main game and press `F2` to enter the Building Constructor.
2. Left-click one of the eight Sub-Units to place or replace the active part. Right-click removes it.
3. Use `1`, `2`, and `3` for Block, Log, and Plank; `M` changes material; `R` changes axis; `V` changes the visual variant; `Y` switches between the lower and upper four Sub-Units.
4. `Tab` switches between gray edit mode and the actual material preview.
5. `Ctrl+S` saves to `user://blueprints/developer_world_unit.pyrbuilding`. `Ctrl+Shift+S` opens Save As, and `Ctrl+O` imports an existing `.pyrbuilding` file.
6. An approved file may be placed under `res://data/buildings/` and shipped as an official prefab.

Runtime code loads either a player file or official prefab through `BuildingBlueprint.load_from_file(path)` and passes it to `BuildingBlueprintInstance.set_blueprint()`. The future construction catalog will add resource reservation and Citizen labour around this same data and renderer; it must not create a second prefab format.
