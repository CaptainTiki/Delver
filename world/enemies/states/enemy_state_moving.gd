extends EnemyState
class_name EnemyStateMoving

func _enter_tree() -> void:
	enemy.animation_player.play("idle")

func _physics_process(delta: float) -> void:
	if enemy.has_registered_player():
		var target := enemy.player.global_position
		target.y = enemy.global_position.y
		if enemy.global_position.distance_to(target) > 0.01:
			enemy.look_at(target)
		if enemy.is_player_within_reach():
			enemy.velocity.x = 0.0
			enemy.velocity.z = 0.0
			enemy.animation_player.play("idle")
			if Time.get_ticks_msec() - enemy.time_since_last_attack > enemy.duration_between_attacks:
				transition_state(Enemy.State.SLASHING)
				return
		else:
			var direction := enemy.global_position.direction_to(target)
			enemy.velocity.x = direction.x * 1.6
			enemy.velocity.z = direction.z * 1.6
			enemy.animation_player.play("run")
	else:
		enemy.animation_player.play("idle")
	enemy.process_movement(delta)
