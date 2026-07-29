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

var pushback_force : Vector3 = Vector3.ZERO
var state : State
var state_node : EnemyState
var time_since_last_attack : float



func _ready() -> void:
	velocity = Vector3.ZERO
	switch_state(State.MOVING)

func switch_state(new_state : State, data: EnemyStateData = EnemyStateData.new()) -> void:
	if state_node != null:
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
	return player != null and is_instance_valid(player)

func is_player_within_reach() -> bool:
	if has_registered_player() and equipment.has_weapon():
		return weapon_reach_raycast.is_colliding()
	return false

func try_receive_hit(source_player: Player, damage: float) -> void:
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

func on_player_detected(body: Player) -> void:
	player = body
	print("player detected")
