extends EnemyState
class_name EnemyStateHurt

const KNOCKBACK_FORCE : float = 1.8

func _enter_tree() -> void:
	enemy.health.take_damage(state_data.damage)
	enemy.pushback_force += state_data.impact_direction * KNOCKBACK_FORCE
	if enemy.health.is_dead():
		var data := EnemyStateData.new().set_impulse(state_data.impact_direction * 120 + Vector3.UP * 80)
		transition_state(Enemy.State.DYING, data)
	else:
		enemy.animation_player.play("hurt")
		enemy.animation_player.animation_finished.connect(on_animation_finished)

func _physics_process(delta: float) -> void:
	enemy.process_movement(delta)

func on_animation_finished(_anim_name: String) -> void:
	transition_state(Enemy.State.MOVING)
