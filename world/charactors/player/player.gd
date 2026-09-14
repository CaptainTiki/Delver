extends CharacterBody3D
class_name Player

@export_category("Mouse Settings")
@export var mouse_sensitivity : float = 0.002
@export var mouse_invert_y : float = 1 # -1 is inverted
@export_category("Movement")
@export var walk_speed : float = 3.0
@export var run_speed : float = 5.0
@export var acceleration : float = 15.0
@export var jump_force : float = 12.0
@export var gravity : float = 0.98


@onready var camera: Camera3D = %Camera3D
@onready var animation_player: AnimationPlayer = $player/AnimationPlayer
@onready var select_raycast: RayCast3D = %SelectRaycast
@onready var equipment: EquipmentComponent = %EquipmentComponent
@onready var weapon_reach_raycast: RayCast3D = %WeaponReachRaycast
@onready var health: HealthComponent = %HealthComponent

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const MAX_ANGLE_LOOK_UP := deg_to_rad(70)
const MAX_ANGLE_LOOK_DOWN := deg_to_rad(-70)

enum State {MOVING, PICKINGUP, THROWING, SLASHING, BLOCKING, DODGING}

var state_node : PlayerState
var state : State
var input_dir : Vector2 = Vector2.ZERO
var current_pickable_focused_item : PickableItem = null

@export_category("Combat")
@export var max_stamina: float = 100.0
@export var attack_cost: float = 15.0
@export var dodge_cost: float = 30.0
var stamina: float = 100.0
var unlimited_stamina: bool = false
var regen_delay: float = 0.0
var stagger_time: float = 0.0
var dodge_elapsed: float = 0.0
var dodge_direction := Vector3.ZERO
var feedback: String = ""
var feedback_time: float = 0.0

func melee_target() -> Enemy:
	# HUD and attack use the same chest-height query, aligned to horizontal aim.
	weapon_reach_raycast.force_raycast_update()
	var target := weapon_reach_raycast.get_collider() as Enemy
	if target != null and target.state not in [Enemy.State.DYING, Enemy.State.DEAD, Enemy.State.IMPALED]:
		return target
	return null

func spend_stamina(amount: float) -> bool:
	if unlimited_stamina:
		stamina = max_stamina
		return true
	if stamina < amount:
		show_feedback("Not enough stamina")
		return false
	stamina -= amount
	regen_delay = 0.8
	return true

func show_feedback(message: String) -> void:
	feedback = message
	feedback_time = 1.0

func receive_hit(source: Node3D, damage: int) -> void:
	if health.is_dead():
		return
	if state == State.DODGING and dodge_elapsed >= 0.05 and dodge_elapsed <= 0.25:
		show_feedback("Dodged")
		return
	var toward := global_position.direction_to(source.global_position)
	toward.y = 0.0
	if state == State.BLOCKING and (-global_basis.z).dot(toward.normalized()) > 0.5:
		if spend_stamina(30.0):
			show_feedback("Blocked")
			return
		stamina = 0.0
		regen_delay = 1.2
		stagger_time = 0.7
		show_feedback("Guard broken")
		switch_state(State.MOVING)
	else:
		show_feedback("Hit")
	health.take_damage(damage)
	if health.is_dead():
		state_node.process_mode = Node.PROCESS_MODE_DISABLED
		animation_player.stop()
		velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	add_to_group("player")
	stamina = max_stamina
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	switch_state(Player.State.MOVING)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_QUOTELEFT:
		unlimited_stamina = not unlimited_stamina
		if unlimited_stamina:
			stamina = max_stamina
			regen_delay = 0.0
		show_feedback("Unlimited stamina ON" if unlimited_stamina else "Normal stamina restored")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and not health.is_dead() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity) # PI 3.14 -> 180 degrees
		camera.rotate_x(-event.relative.y * mouse_sensitivity * mouse_invert_y)
		camera.rotation.x = clamp(camera.rotation.x, MAX_ANGLE_LOOK_DOWN, MAX_ANGLE_LOOK_UP)

func _process(_delta: float) -> void:
	input_dir = Input.get_vector("strafe_left", "strafe_right", "backward", "forward")

func _physics_process(delta: float) -> void:
	if health.is_dead():
		if Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
		return
	regen_delay = maxf(0.0, regen_delay - delta)
	stagger_time = maxf(0.0, stagger_time - delta)
	feedback_time = maxf(0.0, feedback_time - delta)
	if regen_delay <= 0.0 and state == State.MOVING:
		stamina = minf(max_stamina, stamina + 25.0 * delta)
	process_movement(delta)
	check_jump_input()
	process_gravity()
	move_and_slide()
	check_for_selection()

func process_movement(delta: float) -> void:
	var input_3d_space : Vector3 = Vector3(input_dir.x, 0, -input_dir.y)
	var target_speed: float = run_speed if Input.is_action_pressed("run") else walk_speed
	if state == State.DODGING:
		velocity.x = dodge_direction.x * 8.0
		velocity.z = dodge_direction.z * 8.0
		return
	if stagger_time > 0.0:
		target_speed = 0.0
	elif state == State.SLASHING:
		target_speed *= 0.9
	elif state == State.BLOCKING:
		target_speed *= 0.4
	elif state != State.MOVING:
		target_speed *= 0.3
	var desired_velocity : Vector3 = transform.basis * input_3d_space * target_speed
	if input_3d_space == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

func switch_state(new_state : State) -> void:
	if state_node != null:
		state_node.process_mode = Node.PROCESS_MODE_DISABLED
		state_node.queue_free()
	
	var state_map := {
		State.MOVING: PlayerStateMoving,
		State.PICKINGUP: PlayerStatePickingUp,
		State.SLASHING: PlayerStateSlashing,
		State.THROWING: PlayerStateThrowing,
		State.BLOCKING: PlayerStateBlocking,
		State.DODGING: PlayerStateDodging,
	}
	
	state_node = state_map[new_state].new(self)
	state_node.transition_requested.connect(switch_state)
	state_node.name = ("State: " + str(new_state))
	state = new_state
	add_child(state_node)

func check_jump_input() -> void:
	if state == State.MOVING and stagger_time <= 0.0 and is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func process_gravity() -> void:
	if not is_on_floor():
		velocity.y -= gravity * 60.0 * get_physics_process_delta_time()

func check_for_selection() -> void:
	var target_node: Node = null
	if select_raycast.is_colliding():
		var collider := select_raycast.get_collider()
		if collider is PickableItem:
			target_node = collider
	if target_node != current_pickable_focused_item:
		if is_instance_valid(current_pickable_focused_item):
			current_pickable_focused_item.unhighlight()
		current_pickable_focused_item = target_node
		if current_pickable_focused_item is PickableItem:
			current_pickable_focused_item.highlight()

func can_pickup_object() -> bool:
	return is_instance_valid(current_pickable_focused_item)
