extends PlayerState
class_name PlayerStateThrowing

func _enter_tree() -> void:
	player.equipment.throw_weapon()
	transition_state(Player.State.MOVING)
