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

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const MAX_ANGLE_LOOK_UP := deg_to_rad(70)
const MAX_ANGLE_LOOK_DOWN := deg_to_rad(-70)

enum State {MOVING, PICKINGUP, THROWING}

var input_dir : Vector2 = Vector2.ZERO
var current_pickable_focused_item : PickableItem = null

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity) # PI 3.14 -> 180 degrees
		camera.rotate_x(-event.relative.y * mouse_sensitivity * mouse_invert_y)
		camera.rotation.x = clamp(camera.rotation.x, MAX_ANGLE_LOOK_DOWN, MAX_ANGLE_LOOK_UP)

func _process(_delta: float) -> void:
	input_dir = Input.get_vector("strafe_left", "strafe_right", "backward", "forward")
	
	if Input.is_action_just_pressed("use") and can_pickup_object():
		pickup_object()
	
	if Input.is_action_just_pressed("throw") and equipment.has_weapon():
		equipment.throw_weapon()

func _physics_process(delta: float) -> void:
	check_jump_input()
	process_gravity()
	
	var input_3d_space : Vector3 = Vector3(input_dir.x, 0, -input_dir.y)
	var target_speed : float = run_speed if Input.is_action_pressed("run") else walk_speed
	var desired_velocity : Vector3 = transform.basis * input_3d_space * target_speed
	if input_3d_space == Vector3.ZERO:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	
	move_and_slide()
	check_for_selection() 

func switch_state(new_state : State) -> void:
	var state_node := PlayerStateMoving.new(self)
	add_child(state_node)

func check_jump_input() -> void:
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force

func process_gravity() -> void:
	if not is_on_floor():
		velocity.y -= gravity

func check_for_selection() -> void:
	var target_node: Node = null
	if select_raycast.is_colliding():
		var collider := select_raycast.get_collider()
		if collider is PickableItem:
			target_node = collider
	if target_node != current_pickable_focused_item:
		if current_pickable_focused_item:
			current_pickable_focused_item.unhighlight()
		current_pickable_focused_item = target_node
		if current_pickable_focused_item is PickableItem:
			current_pickable_focused_item.highlight()

func can_pickup_object() -> bool:
	return current_pickable_focused_item != null

func pickup_object() -> void:
	var pickable_object := current_pickable_focused_item
	if pickable_object.weapon_data != null:
		equipment.equip_weapon(pickable_object.weapon_data, pickable_object.global_transform)
		pickable_object.queue_free()
