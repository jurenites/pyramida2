class_name DeterministicRandom
extends RefCounted


static func coordinate_seed(x_coordinate: int, z_coordinate: int, salt: int) -> int:
	return absi(x_coordinate * 92837111 + z_coordinate * 689287499 + salt * 283923481)


static func fraction(seed_value: int) -> float:
	return float(absi(seed_value * 73 + 29) % 1001) / 1000.0


static func signed_offset(seed_value: int, maximum: float) -> float:
	return (fraction(seed_value) * 2.0 - 1.0) * maximum


static func detail_fraction(detail_seed: int, index: int, salt: int) -> float:
	var mixed_seed := absi(detail_seed * 1103515245 + index * 12345 + salt * 2654435761)
	return float(mixed_seed % 10001) / 10000.0
