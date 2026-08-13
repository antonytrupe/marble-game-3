class_name FactionMovement

## How quickly velocity blends toward the desired direction (lower = smoother).
const SMOOTHING_FACTOR: float = 1.0
## How quickly the character rotates toward its movement direction (lower = smoother).
const ROTATION_SMOOTHING: float = 1.5
## Forces below this threshold are ignored to prevent micro-jitter.
const DEAD_ZONE: float = 1.5
const MAX_RANGE_SQ: float = FactionRelation.ATTRACT_RANGE * FactionRelation.ATTRACT_RANGE
const SEPARATION_DIST_SQ: float = FactionRelation.SEPARATION_DISTANCE * FactionRelation.SEPARATION_DISTANCE
const REPEL_RANGE_SQ: float = FactionRelation.REPEL_RANGE * FactionRelation.REPEL_RANGE


static func can_move(character: MarbleCharacter) -> bool:
	return character.is_multiplayer_authority() \
			and not character.is_player_controlled() \
			and character.faction.get_main_faction() != FactionStatic.Type.NONE


static func can_influence(character: MarbleCharacter) -> bool:
	return character.faction.get_main_faction() != FactionStatic.Type.NONE


## Returns the force that `other` applies to `character`. The caller can apply
## the inverse to `other`, so a pair only needs to be evaluated once.
static func calculate_pair_force(character: MarbleCharacter, other: MarbleCharacter) -> Vector3:
	var to_other: Vector3 = other.global_position - character.global_position
	var dist_sq: float = to_other.length_squared()
	if dist_sq < 0.01 or dist_sq > MAX_RANGE_SQ:
		return Vector3.ZERO

	if dist_sq < SEPARATION_DIST_SQ:
		return -to_other * (FactionRelation.SEPARATION_STRENGTH / dist_sq)

	var relation: float = character.faction.get_overall_relation(other.faction)
	if relation > 0.0:
		# to_other / dist_sq is equivalent to the former normalized-vector math,
		# without a square-root calculation.
		return to_other * (FactionRelation.ATTRACT_STRENGTH * relation / dist_sq)
	if relation < 0.0 and dist_sq <= REPEL_RANGE_SQ:
		return -to_other * (FactionRelation.REPEL_STRENGTH * absf(relation) / dist_sq)
	return Vector3.ZERO


static func apply_force(character: MarbleCharacter, force: Vector3, delta: float) -> void:
	if force.length_squared() > DEAD_ZONE * DEAD_ZONE:
		var desired: Vector3 = force.normalized() * (FactionRelation.MOVE_SPEED * character.warp_speed)
		var blend: float = clampf(SMOOTHING_FACTOR * delta * character.warp_speed, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, desired.x, blend)
		character.velocity.z = lerpf(character.velocity.z, desired.z, blend)

		var look_target: Vector3 = character.global_position + Vector3(desired.x, 0, desired.z)
		var target_transform: Transform3D = character.global_transform.looking_at(look_target, Vector3.UP)
		var rot_blend: float = clampf(ROTATION_SMOOTHING * delta * character.warp_speed, 0.0, 1.0)
		character.global_transform.basis = character.global_transform.basis.slerp(target_transform.basis, rot_blend)
	else:
		var brake: float = clampf(SMOOTHING_FACTOR * delta * character.warp_speed, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, 0.0, brake)
		character.velocity.z = lerpf(character.velocity.z, 0.0, brake)


## Compatibility helper for isolated character tests. Runtime steering is owned
## by FactionMovementManager, which spatially partitions characters first.
static func apply(character: MarbleCharacter, delta: float) -> void:
	if not can_move(character):
		return

	var force: Vector3 = Vector3.ZERO
	for other: MarbleCharacter in character.get_tree().get_nodes_in_group("character"):
		if other != character and can_influence(other):
			force += calculate_pair_force(character, other)
	apply_force(character, force, delta)
