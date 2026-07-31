class_name FactionMovement

## How quickly velocity blends toward the desired direction (lower = smoother).
const SMOOTHING_FACTOR: float = 1.0
## How quickly the character rotates toward its movement direction (lower = smoother).
const ROTATION_SMOOTHING: float = 1.0
## Forces below this threshold are ignored to prevent micro-jitter.
const DEAD_ZONE: float = 1.0
## Squared max interaction range — siblings farther than this are skipped entirely.
const _MAX_RANGE_SQ: float = FactionRelation.ATTRACT_RANGE * FactionRelation.ATTRACT_RANGE


static func apply(character: MarbleCharacter, delta: float) -> void:
	if not character.is_multiplayer_authority():
		return
	if character._is_player_controlled():
		return
	if character.faction.get_main_faction() == FactionStatic.Type.NONE:
		return

	var attract_dir: Vector3 = Vector3.ZERO
	var repel_dir: Vector3 = Vector3.ZERO
	var my_pos: Vector3 = character.global_position

	var parent: Node = character.get_parent()
	if not parent:
		return

	for sibling: Node in parent.get_children():
		if sibling == character:
			continue
		if not sibling is MarbleCharacter:
			continue
		var other: MarbleCharacter = sibling as MarbleCharacter
		if other.faction.get_main_faction() == FactionStatic.Type.NONE:
			continue

		var to_other: Vector3 = other.global_position - my_pos
		var dist_sq: float = to_other.length_squared()
		if dist_sq < 0.01 or dist_sq > _MAX_RANGE_SQ:
			continue

		var dist: float = sqrt(dist_sq)
		var inv_dist: float = 1.0 / dist
		var direction: Vector3 = to_other * inv_dist
		if dist < FactionRelation.SEPARATION_DISTANCE:
			repel_dir -= direction * inv_dist * FactionRelation.SEPARATION_STRENGTH
		else:
			var relation: float = character.faction.get_overall_relation(other.faction)
			if relation > 0.0 and dist <= FactionRelation.ATTRACT_RANGE:
				attract_dir += direction * inv_dist * FactionRelation.ATTRACT_STRENGTH * relation
			elif relation < 0.0 and dist <= FactionRelation.REPEL_RANGE:
				repel_dir -= direction * inv_dist * FactionRelation.REPEL_STRENGTH * absf(relation)

	var desired: Vector3 = attract_dir + repel_dir
	if desired.length_squared() > DEAD_ZONE * DEAD_ZONE:
		desired = desired.normalized() * FactionRelation.MOVE_SPEED
		var blend: float = clampf(SMOOTHING_FACTOR * delta, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, desired.x, blend)
		character.velocity.z = lerpf(character.velocity.z, desired.z, blend)
		# smoothly rotate toward movement direction
		var look_target: Vector3 = my_pos + Vector3(desired.x, 0, desired.z)
		if my_pos.distance_to(look_target) > 0.01:
			var target_transform: Transform3D = character.global_transform.looking_at(look_target, Vector3.UP)
			var rot_blend: float = clampf(ROTATION_SMOOTHING * delta, 0.0, 1.0)
			character.global_transform.basis = character.global_transform.basis.slerp(target_transform.basis, rot_blend)
	else:
		var brake: float = clampf(SMOOTHING_FACTOR * delta, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, 0.0, brake)
		character.velocity.z = lerpf(character.velocity.z, 0.0, brake)
