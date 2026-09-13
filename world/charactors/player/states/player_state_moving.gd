extends PlayerState
class_name PlayerStateMoving

func _process(_delta: float) -> void:
	if player.stagger_time > 0.0:
		return
	if Input.is_action_just_pressed("dodge") and player.is_on_floor() and player.spend_stamina(player.dodge_cost):
		transition_state(Player.State.DODGING)
		return
	if Input.is_action_pressed("block") and player.equipment.has_weapon():
		transition_state(Player.State.BLOCKING)
		return
	if Input.is_action_just_pressed("use") and player.can_pickup_object():
		transition_state(Player.State.PICKINGUP)
		return
	if Input.is_action_just_pressed("throw") and player.equipment.has_weapon():
		transition_state(Player.State.THROWING)
		return
	if Input.is_action_just_pressed("action") and player.equipment.has_weapon() and player.spend_stamina(player.attack_cost):
		transition_state(Player.State.SLASHING)

func _physics_process(_delta: float) -> void:
	var horizontal := Vector2(player.velocity.x, player.velocity.z)
	player.animation_player.play("run" if horizontal.length() > 0.1 and player.is_on_floor() else "idle")
