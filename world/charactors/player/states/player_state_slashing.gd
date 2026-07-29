extends PlayerState
class_name PlayerStateSlashing

const TIME_EMIT_DAMAGE := 250

var has_emitted_damage : bool = false
var time_start_slash : float = Time.get_ticks_msec() 

func _enter_tree() -> void:
	player.animation_player.play("slash")
	player.animation_player.animation_finished.connect(on_animation_finished)

func on_animation_finished(_anim_name: String) -> void:
	transition_state(Player.State.MOVING)

func _process(delta: float) -> void:
	var time_elapsed : float = Time.get_ticks_msec() - time_start_slash
	if not has_emitted_damage and time_elapsed > TIME_EMIT_DAMAGE:
		has_emitted_damage = true
		if player.weapon_reach_raycast.is_colliding():
			var enemy : Enemy = player.weapon_reach_raycast.get_collider() as Enemy
			if enemy != null:
				var damage := player.equipment.weapon_data.get_damage_delt()
				enemy.try_receive_hit(player, damage)
		
	player.process_movement(delta)
