#!/usr/bin/env python3

import math
import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "tools" / "blender_pyrbuilding"))
import pyrbuilding_codec as codec


class PyramidaBuildingCodecTest(unittest.TestCase):
    def test_official_blueprints_validate_and_round_trip(self):
        for source_path in sorted((PROJECT_ROOT / "data" / "buildings").glob("*.pyrbuilding")):
            source = codec.load_blueprint(source_path)
            with tempfile.TemporaryDirectory() as temporary_directory:
                destination = Path(temporary_directory) / source_path.name
                codec.write_blueprint(destination, source)
                self.assertEqual(codec.load_blueprint(destination), source)

    def test_coordinate_conversion_round_trip(self):
        source = (1.25, 2.5, -3.75)
        converted = codec.pyramida_to_blender(source)
        self.assertEqual(converted, (1.25, 3.75, 2.5))
        self.assertEqual(codec.blender_to_pyramida(converted), source)

    def test_sub_unit_uses_half_world_unit_grid_and_clamps_edges(self):
        self.assertEqual(codec.nearest_sub_unit((-0.36, 0.02, -0.36), (1, 1, 1)), [0, 0, 0])
        self.assertEqual(codec.nearest_sub_unit((0.36, 0.99, 0.36), (1, 1, 1)), [1, 1, 1])
        self.assertEqual(codec.nearest_sub_unit((1.5, 0.08, 1.5), (2, 1, 2)), [3, 0, 3])

    def test_non_finite_geometry_is_rejected(self):
        source_path = PROJECT_ROOT / "data" / "buildings" / "four_log_support.pyrbuilding"
        blueprint = codec.load_blueprint(source_path)
        blueprint["parts"][0]["geometry"]["start"][0] = math.nan
        with self.assertRaisesRegex(ValueError, "non-finite"):
            codec.validate_blueprint(blueprint)
        with tempfile.TemporaryDirectory() as temporary_directory:
            with self.assertRaises(ValueError):
                codec.write_blueprint(Path(temporary_directory) / "invalid.pyrbuilding", blueprint)


if __name__ == "__main__":
    unittest.main()
