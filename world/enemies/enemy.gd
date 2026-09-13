extends CharacterBody3D
class_name Enemy

const RAGDOLL_SIMULATION_TIME : float = 3.0
const GRAVITY : float = 20.0
const FRICTION : float = 20.0

@onready var physical_bone_torso: PhysicalBone3D = %"Physical Bone Torso"
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var skeleton_simulator: PhysicalBoneSimulator3D = %PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $player/AnimationPlayer
@onready var equipment: EquipmentComponent = %EquipmentComponent
@onready var player_detection_area: Area3D = %PlayerDetectionArea
@onready var weapon_reach_raycast: RayCast3D = $WeaponReachRaycast
@onready var health: HealthComponent = %HealthComponent

@export var duration_between_attacks: float
@export var player: Player

enum State {MOVING, IMPALED, HURT, DYING, DEAD, SLASHING}

@export var melee_reach: float = 1.2
var combat_phase: String = ""
var phase_label: Label3D

var pushback_force : Vector3 = Vector3.ZERO
var state : State
var state_node : EnemyState
var time_since_last_attack : float



func _ready() -> void:
	weapon_reach_raycast.target_position.z = -melee_reach
	phase_label = Label3D.new()
	phase_label.position = Vector3(0, 2.25, 0)
	phase_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	phase_label.font_size = 32
	phase_label.pixel_size = 0.004
	add_child(phase_label)
	velocity = Vector3.ZERO
	switch_state(State.MOVING)

func _process(_delta: float) -> void:
	phase_label.text = combat_phase
	phase_label.modulate = Color(0.4, 1.0, 0.5) if combat_phase.begins_with("RECOVERING") else Color(1.0, 0.65, 0.2)

func switch_state(new_state : State, data: EnemyStateData = EnemyStateData.new()) -> void:
	combat_phase = ""
	if state_node != null:
		state_node.process_mode = Node.PROCESS_MODE_DISABLED
		state_node.queue_free()
	
	var state_map := {
		State.MOVING: EnemyStateMoving,
		State.IMPALED: EnemyStateImpaled,
		State.DYING: EnemyStateDying,
		State.DEAD: EnemyStateDead,
		State.HURT: EnemyStateHurt,
		State.SLASHING: EnemyStateSlashing,
	}
	
	state_node = state_map[new_state].new(self, data)
	state_node.transition_requested.connect(switch_state)
	state_node.name = ("State: " + str(new_state))
	state = new_state
	add_child(state_node)

func impale(thrown_item: ThrownItem, item_basis : Basis) -> void:
	var state_data : EnemyStateData = EnemyStateData.new().set_thrown_item(thrown_item).set_thrown_item_basis(item_basis)
	switch_state(State.IMPALED, state_data)

func has_registered_player() -> bool:
	return is_instance_valid(player) and not player.health.is_dead()

func is_player_within_reach() -> bool:
	if has_registered_player() and equipment.has_weapon():
		weapon_reach_raycast.force_raycast_update()
		return weapon_reach_raycast.get_collider() == player
	return false

func try_receive_hit(source_player: Player, damage: float) -> void:
	if state in [State.DYING, State.DEAD, State.IMPALED]:
		return
	var hit_direction := source_player.global_position.direction_to(global_position).normalized()
	switch_state(State.HURT, EnemyStateData.new().set_damage(damage).set_impact_direction(hit_direction))


func process_movement(delta: float) -> void:
	process_gravity(delta)
	process_pushback(delta)
	move_and_slide()
	velocity = velocity.move_toward(Vector3.ZERO, delta * FRICTION)
	pass

func process_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func process_pushback(delta: float) -> void:
	pushback_force = pushback_force.move_toward(Vector3.ZERO, delta * FRICTION)
	velocity += pushback_force

func on_player_detected(body: Node3D) -> void:
	if body is Player:
		player = body
