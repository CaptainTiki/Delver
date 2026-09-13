extends PlayerState
class_name PlayerStateBlocking

var resting_transform: Transform3D

func _enter_tree() -> void:
	player.animation_player.play("idle")
	resting_transform = player.equipment.hand_slot.transform
	player.equipment.hand_slot.position += Vector3(-0.15, 0.15, 0.0)
	player.equipment.hand_slot.rotate_object_local(Vector3.FORWARD, 0.7)

func _process(_delta: float) -> void:
	if not Input.is_action_pressed("block"):
		transition_state(Player.State.MOVING)
	elif Input.is_action_just_pressed("dodge") and player.is_on_floor() and player.spend_stamina(player.dodge_cost):
		transition_state(Player.State.DODGING)

func _exit_tree() -> void:
	player.equipment.hand_slot.transform = resting_transform
