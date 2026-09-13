extends EnemyState
class_name EnemyStateSlashing

const WINDUP := 0.8
const STRIKE := 0.18
const RECOVERY := 1.1
const HIT_TIME := WINDUP + 0.09
var elapsed: float = 0.0
var hit_checked: bool = false
var animation_length: float = 1.0

func _enter_tree() -> void:
	enemy.velocity = Vector3.ZERO
	animation_length = enemy.animation_player.get_animation("slash").length
	enemy.animation_player.play("slash")
	enemy.animation_player.pause()
	enemy.combat_phase = "WINDUP — back away"

func _physics_process(delta: float) -> void:
	elapsed += delta
	# Explicitly sample the animation so the anticipation, contact and recovery
	# cannot drift away from the damage timing as playback speeds change.
	var pose: float
	if elapsed < WINDUP:
		pose = lerpf(0.0, 0.22, elapsed / WINDUP)
		enemy.combat_phase = "WINDUP — back away"
	elif elapsed < WINDUP + STRIKE:
		pose = lerpf(0.22, 0.65, (elapsed - WINDUP) / STRIKE)
		enemy.combat_phase = "STRIKE"
	else:
		pose = lerpf(0.65, 1.0, clampf((elapsed - WINDUP - STRIKE) / RECOVERY, 0.0, 1.0))
		enemy.combat_phase = "RECOVERING — opening"
	enemy.animation_player.seek(pose * animation_length, true)
	if not hit_checked and elapsed >= HIT_TIME:
		hit_checked = true
		if enemy.is_player_within_reach():
			enemy.player.receive_hit(enemy, 6)
		elif enemy.has_registered_player():
			enemy.player.show_feedback("Enemy missed — step in")
	# No tracking or horizontal movement once the attack is committed.
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0
	enemy.process_gravity(delta)
	enemy.move_and_slide()
	if elapsed >= WINDUP + STRIKE + RECOVERY:
		enemy.time_since_last_attack = Time.get_ticks_msec()
		transition_state(Enemy.State.MOVING)
