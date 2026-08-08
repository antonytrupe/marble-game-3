class_name FactionMovement

## How quickly velocity blends toward the desired direction (lower = smoother).
const SMOOTHING_FACTOR: float = 1.0
## How quickly the character rotates toward its movement direction (lower = smoother).
const ROTATION_SMOOTHING: float = 1.5
## Forces below this threshold are ignored to prevent micro-jitter.
const DEAD_ZONE: float = 1.5
## Pre-computed squared distance thresholds to avoid per-frame sqrt calls.
const _MAX_RANGE_SQ: float = FactionRelation.ATTRACT_RANGE * FactionRelation.ATTRACT_RANGE
const _SEPARATION_DIST_SQ: float = FactionRelation.SEPARATION_DISTANCE * FactionRelation.SEPARATION_DISTANCE
const _REPEL_RANGE_SQ: float = FactionRelation.REPEL_RANGE * FactionRelation.REPEL_RANGE


static func apply(character: MarbleCharacter, delta: float) -> void:
	#var start_time = Time.get_ticks_usec()

	if not character.is_multiplayer_authority():
		return
	if character._is_player_controlled():
		return
	if character.faction.get_main_faction() == FactionStatic.Type.NONE:
		return

	var attract_dir: Vector3 = Vector3.ZERO
	var repel_dir: Vector3 = Vector3.ZERO
	var my_pos: Vector3 = character.global_position
	var my_faction: Faction = character.faction

	for other: MarbleCharacter in character.get_tree().get_nodes_in_group("character"):
		if other == character:
			continue
		if other.faction.get_main_faction() == FactionStatic.Type.NONE:
			continue

		var to_other: Vector3 = other.global_position - my_pos
		var dist_sq: float = to_other.length_squared()
		if dist_sq < 0.01 or dist_sq > _MAX_RANGE_SQ:
			continue

		# line of sight check – skip if something blocks the view
		# query.from = my_pos
		# query.to = other.global_position
		# var result: Dictionary = space_state.intersect_ray(query)
		# if not result.is_empty() and result.collider != other:
		# 	continue

		if dist_sq < _SEPARATION_DIST_SQ:
			# Force ∝ 1/dist²: original was direction * inv_dist = to_other / dist².
			# Avoid sqrt by computing to_other / dist_sq directly.
			repel_dir -= to_other * (FactionRelation.SEPARATION_STRENGTH / dist_sq)
		else:
			var relation: float = my_faction.get_overall_relation(other.faction)
			if relation > 0.0:
				# Already guaranteed dist <= ATTRACT_RANGE by _MAX_RANGE_SQ check.
				var inv_dist: float = 1.0 / sqrt(dist_sq)
				var direction: Vector3 = to_other * inv_dist
				attract_dir += direction * inv_dist * FactionRelation.ATTRACT_STRENGTH * relation
			elif relation < 0.0 and dist_sq <= _REPEL_RANGE_SQ:
				var inv_dist: float = 1.0 / sqrt(dist_sq)
				var direction: Vector3 = to_other * inv_dist
				repel_dir -= direction * inv_dist * FactionRelation.REPEL_STRENGTH * absf(relation)

	var desired: Vector3 = attract_dir + repel_dir
	if desired.length_squared() > DEAD_ZONE * DEAD_ZONE:
		desired = desired.normalized() * (FactionRelation.MOVE_SPEED * character.warp_speed)
		var blend: float = clampf(SMOOTHING_FACTOR * delta * character.warp_speed, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, desired.x, blend)
		character.velocity.z = lerpf(character.velocity.z, desired.z, blend)
		# smoothly rotate toward movement direction
		var look_target: Vector3 = my_pos + Vector3(desired.x, 0, desired.z)
		if my_pos.distance_to(look_target) > 0.01:
			var target_transform: Transform3D = character.global_transform.looking_at(look_target, Vector3.UP)
			var rot_blend: float = clampf(ROTATION_SMOOTHING * delta * character.warp_speed, 0.0, 1.0)
			character.global_transform.basis = character.global_transform.basis.slerp(target_transform.basis, rot_blend)
	else:
		var brake: float = clampf(SMOOTHING_FACTOR * delta * character.warp_speed, 0.0, 1.0)
		character.velocity.x = lerpf(character.velocity.x, 0.0, brake)
		character.velocity.z = lerpf(character.velocity.z, 0.0, brake)
	#print("faction_movement.apply: ", Time.get_ticks_usec() - start_time, " us")
