extends PlayerState
class_name PlayerStateThrowing

func _enter_tree() -> void:
	player.animation_player.play("throw_weapon")
	player.animation_player.animation_finished.connect(on_animation_finished)

func on_animation_finished(_anim_name: String) -> void:
	player.equipment.throw_weapon()
	transition_state(Player.State.MOVING)
