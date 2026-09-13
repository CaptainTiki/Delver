extends EnemyState
class_name EnemyStateSlashing

var elapsed: float = 0.0
var hit_checked: bool = false

func _enter_tree() -> void:
	enemy.velocity = Vector3.ZERO
	# Stretch the existing windup, then release the swing without tracking the player.
	enemy.animation_player.play("slash", -1, 0.4)

func _exit_tree() -> void:
	enemy.animation_player.speed_scale = 1.0

func _physics_process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.5:
		enemy.animation_player.speed_scale = 2.5
	if not hit_checked and elapsed >= 0.65:
		hit_checked = true
		if enemy.is_player_within_reach():
			enemy.player.receive_hit(enemy, 6)
	enemy.process_movement(delta)
	if elapsed >= 1.25:
		enemy.time_since_last_attack = Time.get_ticks_msec()
		transition_state(Enemy.State.MOVING)
