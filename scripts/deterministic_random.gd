class_name DeterministicRandom
extends RefCounted


static func coordinate_seed(x_coordinate: int, z_coordinate: int, salt: int) -> int:
	return absi(x_coordinate * 92837111 + z_coordinate * 689287499 + salt * 283923481)


## A cross-platform, random-access hash for permanent world generation.
##
## The original coordinate_seed() is deliberately retained because the origin
## fixture and existing visual details already depend on it. It is a linear
## congruence, however, so reducing it into a small range exposes diagonal
## bands. Permanent generator version 2 uses SHA-256's avalanche instead. The
## formatted integer input and the first 60 digest bits have identical meaning
## on every supported machine and do not depend on query or traversal order.
static func world_coordinate_seed(
	x_coordinate: int,
	z_coordinate: int,
	world_seed: int,
	channel: int
) -> int:
	var source := "pyramida-world-v2|%d|%d|%d|%d" % [
		world_seed,
		x_coordinate,
		z_coordinate,
		channel,
	]
	return source.sha256_text().substr(0, 15).hex_to_int()


static func world_fraction(
	x_coordinate: int,
	z_coordinate: int,
	world_seed: int,
	channel: int
) -> float:
	return float(world_coordinate_seed(x_coordinate, z_coordinate, world_seed, channel) % 1000001) / 1000000.0


## Smooth deterministic habitat noise. This affects the probability of a
## resource appearing, while world_fraction() decides the individual cell.
## Combining the two creates natural patches without repeating a chunk tile or
## making generation depend on neighbouring chunks being loaded first.
static func habitat_noise(
	x_coordinate: int,
	z_coordinate: int,
	world_seed: int,
	channel: int,
	cell_size := 13
) -> float:
	var safe_cell_size := maxi(1, cell_size)
	var lattice_x := floori(float(x_coordinate) / float(safe_cell_size))
	var lattice_z := floori(float(z_coordinate) / float(safe_cell_size))
	var local_x := float(x_coordinate - lattice_x * safe_cell_size) / float(safe_cell_size)
	var local_z := float(z_coordinate - lattice_z * safe_cell_size) / float(safe_cell_size)
	var smooth_x := local_x * local_x * (3.0 - 2.0 * local_x)
	var smooth_z := local_z * local_z * (3.0 - 2.0 * local_z)
	var north_west := world_fraction(lattice_x, lattice_z, world_seed, channel)
	var north_east := world_fraction(lattice_x + 1, lattice_z, world_seed, channel)
	var south_west := world_fraction(lattice_x, lattice_z + 1, world_seed, channel)
	var south_east := world_fraction(lattice_x + 1, lattice_z + 1, world_seed, channel)
	return lerpf(
		lerpf(north_west, north_east, smooth_x),
		lerpf(south_west, south_east, smooth_x),
		smooth_z
	)


static func fraction(seed_value: int) -> float:
	return float(absi(seed_value * 73 + 29) % 1001) / 1000.0


static func signed_offset(seed_value: int, maximum: float) -> float:
	return (fraction(seed_value) * 2.0 - 1.0) * maximum


static func detail_fraction(detail_seed: int, index: int, salt: int) -> float:
	var mixed_seed := absi(detail_seed * 1103515245 + index * 12345 + salt * 2654435761)
	return float(mixed_seed % 10001) / 10000.0
