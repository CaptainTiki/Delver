extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world: Node3D = load("res://world/world.tscn").instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player") as Player
	var enemy := world.current_loaded_level.get_node("Goblin") as Enemy
	enemy.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	player.equipment.equip_weapon(load("res://data/weapons/sword.tres"))
	var source := Node3D.new()
	get_tree().root.add_child(source)
	source.global_position = player.global_position - player.global_basis.z
	player.receive_hit(source, 6)
	assert(player.health.current_life == 24, "Unblocked hit must damage health")
	player.switch_state(Player.State.BLOCKING)
	player.receive_hit(source, 6)
	assert(player.health.current_life == 24 and player.stamina == 70.0, "Frontal block spends stamina")
	source.global_position = player.global_position + player.global_basis.z
	player.receive_hit(source, 6)
	assert(player.health.current_life == 18, "Rear attacks bypass guard")
	source.global_position = player.global_position - player.global_basis.z
	player.stamina = 10.0
	player.receive_hit(source, 6)
	assert(player.health.current_life == 12 and player.stagger_time > 0.0, "Exhausted guard breaks")
	player.switch_state(Player.State.DODGING)
	player.dodge_elapsed = 0.1
	player.receive_hit(source, 6)
	assert(player.health.current_life == 12, "Dodge window avoids damage")
	player.dodge_elapsed = 0.3
	player.receive_hit(source, 6)
	assert(player.health.current_life == 6, "Dodge recovery is vulnerable")
	assert(not player.spend_stamina(25), "Cannot overspend stamina")
	player.switch_state(Player.State.MOVING)
	player.stagger_time = 0.0
	player.regen_delay = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(player.stamina > 0.0, "Resting restores stamina")
	player.receive_hit(source, 6)
	assert(player.health.is_dead(), "Lethal damage ends player actions")
	print("COMBAT_TEST: PASS - damage, frontal/rear guard, guard break, dodge window, recovery, stamina, death")
	# Exercise the real enemy state and raycast in an unobstructed test space.
	player.health.current_life = 30
	player.switch_state(Player.State.MOVING)
	player.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(0, 10, 0)
	enemy.global_position = Vector3(0, 10, -1.5)
	enemy.look_at(player.global_position)
	enemy.player = player
	enemy.state_node.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().physics_frame
	await get_tree().physics_frame
	enemy.switch_state(Enemy.State.SLASHING)
	enemy.state_node._physics_process(0.66)
	assert(player.health.current_life == 24, "Enemy swing must damage player through its raycast")
	enemy.state_node._physics_process(0.1)
	assert(player.health.current_life == 24, "Swing may damage only once")
	enemy.state_node._physics_process(0.6)
	assert(enemy.state == Enemy.State.MOVING, "Enemy returns to movement after recovery")
	enemy.global_position = Vector3(0, 10, -6)
	await get_tree().physics_frame
	enemy.state_node._physics_process(0.016)
	assert(enemy.velocity.z > 0.0, "Enemy approaches detected player")
	print("ENEMY_TEST: PASS - approach, timed hit, single damage, recovery")
	source.queue_free()
	world.queue_free()
	await get_tree().process_frame
	get_tree().quit()
