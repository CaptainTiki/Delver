extends PlayerState
class_name PlayerStateDodging

func _enter_tree() -> void:
	player.dodge_elapsed = 0.0
	var direction := Vector3(player.input_dir.x, 0.0, -player.input_dir.y)
	if direction.is_zero_approx():
		direction = Vector3.BACK
	player.dodge_direction = (player.global_basis * direction).normalized()
	player.animation_player.play("idle")

func _physics_process(delta: float) -> void:
	player.dodge_elapsed += delta
	if player.dodge_elapsed >= 0.35:
		player.velocity.x = 0.0
		player.velocity.z = 0.0
		transition_state(Player.State.MOVING)
