extends EnemyState
class_name EnemyStateDying

const RAGDOLL_SIMULATION_TIME : float = 3.0

func _enter_tree() -> void:
	enemy.equipment.throw_weapon(true)
	enemy.animation_player.stop()
	enemy.collision_shape.disabled = true
	enemy.skeleton_simulator.active = true
	enemy.skeleton_simulator.physical_bones_start_simulation()
	enemy.physical_bone_torso.apply_impulse(state_data.impulse)
	get_tree().create_timer(RAGDOLL_SIMULATION_TIME).timeout.connect(freeze_ragdoll)

func freeze_ragdoll() -> void:
	transition_state(Enemy.State.DEAD)
