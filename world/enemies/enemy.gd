extends CharacterBody3D
class_name Enemy

const RAGDOLL_SIMULATION_TIME : float = 3.0

@onready var physical_bone_torso: PhysicalBone3D = %"Physical Bone Torso"
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var skeleton_simulator: PhysicalBoneSimulator3D = %PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $player/AnimationPlayer

enum State {MOVING, IMPALED, DYING, DEAD}

var state : State
var state_node : EnemyState

func _ready() -> void:
	switch_state(State.MOVING)

func switch_state(new_state : State, data: EnemyStateData = EnemyStateData.new()) -> void:
	if state_node != null:
		state_node.queue_free()
	
	var state_map := {
		State.MOVING: EnemyStateMoving,
		State.IMPALED: EnemyStateImpaled
	}
	
	state_node = state_map[new_state].new(self, data)
	state_node.transition_requested.connect(switch_state)
	state_node.name = ("State: " + str(new_state))
	state = new_state
	add_child(state_node)

func impale(thrown_item: ThrownItem, item_basis : Basis) -> void:
	var state_data : EnemyStateData = EnemyStateData.new()
	state_data.thrown_item = thrown_item
	state_data.thrown_item_basis = item_basis
	switch_state(State.IMPALED, state_data)

func register_death(impulse: Vector3 = Vector3.ZERO) -> void:
	animation_player.stop()
	collision_shape.disabled = true
	skeleton_simulator.active = true
	skeleton_simulator.physical_bones_start_simulation()
	physical_bone_torso.apply_impulse(impulse)
	get_tree().create_timer(RAGDOLL_SIMULATION_TIME).timeout.connect(freeze_ragdoll)

func freeze_ragdoll() -> void:
	for child in skeleton_simulator.get_children():
		var physical_bone := child as PhysicalBone3D

		# Kill any remaining momentum first.
		physical_bone.linear_velocity = Vector3.ZERO
		physical_bone.angular_velocity = Vector3.ZERO
		physical_bone.can_sleep = true

		# Force this physical body to sleep in its current pose.
		PhysicsServer3D.body_set_state(
			physical_bone.get_rid(),
			PhysicsServer3D.BODY_STATE_SLEEPING,
			true
		)
