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
	# A floor keeps large manual physics steps from turning misses into fall-away misses.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	get_tree().root.add_child(floor_body)
	floor_body.global_position = Vector3(0, 9.5, 0)
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
	enemy.state_node._physics_process(0.90)
	assert(player.health.current_life == 24, "Enemy swing must damage player through its raycast")
	enemy.state_node._physics_process(0.1)
	assert(player.health.current_life == 24, "Swing may damage only once")
	enemy.state_node._physics_process(1.2)
	assert(enemy.state == Enemy.State.MOVING, "Enemy returns to movement after recovery")
	enemy.global_position = Vector3(0, 10, -6)
	await get_tree().physics_frame
	enemy.state_node._physics_process(0.016)
	assert(enemy.velocity.z > 0.0, "Enemy approaches detected player")
	print("ENEMY_TEST: PASS - approach, timed hit, single damage, recovery")
	# Reproduce the intended spacing loop: bait, retreat, punish without a trade.
	player.global_position = Vector3(0, 10, 0)
	player.rotation = Vector3.ZERO
	enemy.global_position = Vector3(0, 10, -1.5)
	enemy.look_at(player.global_position)
	enemy.velocity = Vector3.ZERO
	await get_tree().physics_frame
	enemy.switch_state(Enemy.State.SLASHING)
	var before: int = player.health.current_life
	var facing := enemy.global_basis
	enemy.state_node._physics_process(0.4)
	assert(player.health.current_life == before, "Windup cannot damage")
	player.global_position.z = 0.55
	await get_tree().physics_frame
	enemy.state_node._physics_process(0.5)
	assert(player.health.current_life == before, "Backing out of reach avoids the strike")
	assert(enemy.global_basis.is_equal_approx(facing), "Committed attack must not track")
	enemy.state_node._physics_process(0.1)
	assert(enemy.combat_phase.begins_with("RECOVERING"), "Miss opens recovery window")
	enemy.global_position = Vector3(0, 10, -1.5)
	enemy.velocity = Vector3.ZERO
	player.global_position.z = 0.0
	await get_tree().physics_frame
	assert(player.melee_target() == enemy, "Sword reaches the recovering goblin")
	var enemy_before: int = enemy.health.current_life
	player.switch_state(Player.State.SLASHING)
	for sample in range(24):
		player.state_node._physics_process(0.016)
	assert(enemy.health.current_life < enemy_before, "Punish swing connects")
	assert(player.health.current_life == before, "Successful spacing causes no health trade")
	print("SPACING_TEST: PASS - bait, retreat, locked facing, recovery, damage-free punish")
	# Full sequence: no automatic repeat, one buffered cut, stamina, finite finish.
	player.switch_state(Player.State.MOVING)
	await get_tree().process_frame
	enemy.health.max_life = 100
	enemy.health.current_life = 100
	enemy.switch_state(Enemy.State.MOVING)
	enemy.global_position = Vector3(0, 10, -1.25)
	player.stamina = 100.0
	player.switch_state(Player.State.SLASHING)
	var attack := player.state_node as PlayerStateSlashing
	attack.queue_followup()
	assert(not attack.queued, "Opening click cannot queue an immediate extra attack")
	for i in range(4):
		attack._physics_process(0.016)
	attack.queue_followup()
	assert(attack.queued, "Follow-up accepts a click during early windup")
	while attack.cut == 0:
		attack._physics_process(0.016)
	assert(player.stamina == 85.0, "Follow-up spends stamina once")
	for i in range(12):
		attack._physics_process(0.016)
	attack.queue_followup()
	while attack.cut == 1:
		attack._physics_process(0.016)
	assert(player.stamina == 70.0, "Third cut spends stamina once")
	attack.queue_followup()
	assert(not attack.queued, "Finisher cannot queue a fourth cut")
	for i in range(65):
		if player.state != Player.State.SLASHING:
			break
		attack._physics_process(0.016)
	assert(player.state == Player.State.MOVING, "Finisher recovers to movement")
	assert(enemy.health.current_life < 100, "Blade sweep connects during sequence")
	await get_tree().process_frame
	player.switch_state(Player.State.SLASHING)
	attack = player.state_node
	for i in range(60):
		if player.state != Player.State.SLASHING:
			break
		attack._physics_process(0.016)
	assert(player.state == Player.State.MOVING and attack.cut == 0, "Single click plays only one cut")
	print("COMBO_TEST: PASS - input buffer, stamina per follow-up, three-cut cap, single-cut release")
	floor_body.queue_free()
	source.queue_free()
	world.queue_free()
	await get_tree().process_frame
	get_tree().quit()
