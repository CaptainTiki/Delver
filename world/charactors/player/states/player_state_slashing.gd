extends PlayerState
class_name PlayerStateSlashing

func _enter_tree() -> void:
	player.animation_player.play("slash")
	player.animation_player.animation_finished.connect(on_animation_finished)

func on_animation_finished(_anim_name: String) -> void:
	transition_state(Player.State.MOVING)

func _process(delta: float) -> void:
	player.process_movement(delta)
