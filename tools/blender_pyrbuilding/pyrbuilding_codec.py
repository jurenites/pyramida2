"""Pure-Python helpers shared by the Pyramida Blender extension tests."""

from __future__ import annotations

import json
import math
from pathlib import Path
from typing import Any, Iterable, Sequence

FORMAT_ID = "pyramida-building"
SUPPORTED_FORMAT_VERSIONS = {1, 2}
SUPPORTED_PART_KINDS = {"block", "log", "plank"}
SUPPORTED_PRIMITIVES = {"box", "log", "sphere"}
SUPPORTED_MATERIALS = {"wood", "limestone", "marble", "concrete"}
MATERIAL_COLOURS = {
    "wood": (0xE0 / 255.0, 0x81 / 255.0, 0x60 / 255.0, 1.0),
    "limestone": (0xEE / 255.0, 0xBF / 255.0, 0x8A / 255.0, 1.0),
    "marble": (0xF3 / 255.0, 0xEE / 255.0, 0xE5 / 255.0, 1.0),
    "concrete": (0x8A / 255.0, 0x8D / 255.0, 0x8F / 255.0, 1.0),
}


def pyramida_to_blender(value: Sequence[float]) -> tuple[float, float, float]:
    """Map Pyramida/Godot X-right, Y-up, Z-back to Blender X, Y, Z-up."""
    x_value, y_value, z_value = _finite_vector(value, "coordinate")
    return (x_value, -z_value, y_value)


def blender_to_pyramida(value: Sequence[float]) -> tuple[float, float, float]:
    x_value, y_value, z_value = _finite_vector(value, "coordinate")
    return (x_value, z_value, -y_value)


def sub_unit_centre(sub_unit: Sequence[int]) -> tuple[float, float, float]:
    x_value, y_value, z_value = (int(component) for component in sub_unit)
    return (-0.25 + 0.5 * x_value, 0.25 + 0.5 * y_value, -0.25 + 0.5 * z_value)


def nearest_sub_unit(anchor_position: Sequence[float], bounds_world_units: Sequence[int]) -> list[int]:
    anchor = _finite_vector(anchor_position, "anchor")
    bounds = [int(component) for component in bounds_world_units]
    if len(bounds) != 3 or any(component <= 0 for component in bounds):
        raise ValueError("Blueprint bounds must contain three positive World Unit values")
    raw = (
        math.floor((anchor[0] + 0.5) * 2.0 + 1.0e-7),
        math.floor(anchor[1] * 2.0 + 1.0e-7),
        math.floor((anchor[2] + 0.5) * 2.0 + 1.0e-7),
    )
    return [max(0, min(raw[axis], bounds[axis] * 2 - 1)) for axis in range(3)]


def load_blueprint(filepath: str | Path) -> dict[str, Any]:
    with Path(filepath).open("r", encoding="utf-8") as source_file:
        blueprint = json.load(source_file)
    validate_blueprint(blueprint)
    return blueprint


def write_blueprint(filepath: str | Path, blueprint: dict[str, Any]) -> None:
    validate_blueprint(blueprint)
    destination = Path(filepath)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="\n") as output_file:
        json.dump(blueprint, output_file, indent="\t", ensure_ascii=False, allow_nan=False)
        output_file.write("\n")


def validate_blueprint(blueprint: Any) -> None:
    if not isinstance(blueprint, dict):
        raise ValueError("A Pyramida Building must contain one JSON object")
    if blueprint.get("format") != FORMAT_ID:
        raise ValueError("Unsupported blueprint format")
    if int(blueprint.get("format_version", 0)) not in SUPPORTED_FORMAT_VERSIONS:
        raise ValueError("Unsupported blueprint format version")
    if not str(blueprint.get("id", "")).strip():
        raise ValueError("Blueprint ID is required")
    bounds = blueprint.get("bounds_world_units")
    if not isinstance(bounds, list) or len(bounds) != 3 or any(int(value) <= 0 for value in bounds):
        raise ValueError("Blueprint bounds must contain three positive World Unit values")
    parts = blueprint.get("parts")
    if not isinstance(parts, list):
        raise ValueError("Blueprint parts must be an array")
    used_ids: set[str] = set()
    for part in parts:
        _validate_part(part, bounds, used_ids)


def geometry_reference(part: dict[str, Any]) -> tuple[float, float, float]:
    geometry = part.get("geometry", {})
    primitive = geometry.get("primitive", "log" if part.get("kind") == "log" else "box")
    if primitive == "log":
        start = _finite_vector(geometry.get("start", (0.0, 0.0, 0.0)), "log start")
        end = _finite_vector(geometry.get("end", (0.0, 0.5, 0.0)), "log end")
        return tuple((start[index] + end[index]) * 0.5 for index in range(3))
    return _finite_vector(geometry.get("centre", (0.0, 0.0, 0.0)), "part centre")


def _validate_part(part: Any, bounds: Sequence[int], used_ids: set[str]) -> None:
    if not isinstance(part, dict):
        raise ValueError("Every blueprint part must be an object")
    part_id = str(part.get("id", "")).strip()
    if not part_id or part_id in used_ids:
        raise ValueError("Blueprint part IDs must be present and unique")
    used_ids.add(part_id)
    if part.get("kind") not in SUPPORTED_PART_KINDS:
        raise ValueError(f"Unsupported blueprint part kind: {part.get('kind')}")
    if part.get("material") not in SUPPORTED_MATERIALS:
        raise ValueError(f"Unsupported building material: {part.get('material')}")
    sub_unit = part.get("sub_unit")
    if not isinstance(sub_unit, list) or len(sub_unit) != 3:
        raise ValueError(f"Part {part_id} has no valid Sub-Unit")
    for axis, value in enumerate(sub_unit):
        if int(value) < 0 or int(value) >= int(bounds[axis]) * 2:
            raise ValueError(f"Part {part_id} lies outside the Building bounds")
    geometry = part.get("geometry")
    if not isinstance(geometry, dict):
        raise ValueError(f"Part {part_id} geometry must be an object")
    primitive = geometry.get("primitive", "log" if part.get("kind") == "log" else "box")
    if primitive not in SUPPORTED_PRIMITIVES:
        raise ValueError(f"Part {part_id} uses unsupported primitive {primitive}")
    for value in _numeric_values(geometry):
        if not math.isfinite(value):
            raise ValueError(f"Part {part_id} contains a non-finite geometry value")


def _numeric_values(value: Any) -> Iterable[float]:
    if isinstance(value, bool):
        return
    if isinstance(value, (int, float)):
        yield float(value)
    elif isinstance(value, dict):
        for child in value.values():
            yield from _numeric_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from _numeric_values(child)


def _finite_vector(value: Sequence[float], label: str) -> tuple[float, float, float]:
    if len(value) != 3:
        raise ValueError(f"{label} must contain exactly three values")
    result = tuple(float(component) for component in value)
    if not all(math.isfinite(component) for component in result):
        raise ValueError(f"{label} contains NaN or infinity")
    return result
