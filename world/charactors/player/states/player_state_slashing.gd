extends PlayerState
class_name PlayerStateSlashing

var elapsed: float = 0.0
var hit_checked: bool = false

func _enter_tree() -> void:
	player.animation_player.play("slash")

func _physics_process(delta: float) -> void:
	elapsed += delta
	if not hit_checked and elapsed >= 0.25:
		hit_checked = true
		player.weapon_reach_raycast.force_raycast_update()
		var enemy := player.weapon_reach_raycast.get_collider() as Enemy
		if enemy != null:
			enemy.try_receive_hit(player, player.equipment.weapon_data.get_damage_delt())
	if elapsed >= 0.75:
		transition_state(Player.State.MOVING)
