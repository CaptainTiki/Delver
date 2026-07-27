extends CharacterBody3D
class_name Enemy

const RAGDOLL_SIMULATION_TIME : float = 3.0

@onready var physical_bone_torso: PhysicalBone3D = %"Physical Bone Torso"
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var skeleton_simulator: PhysicalBoneSimulator3D = %PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $player/AnimationPlayer
@onready var equipment: EquipmentComponent = %EquipmentComponent

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
		State.IMPALED: EnemyStateImpaled,
		State.DYING: EnemyStateDying,
		State.DEAD: EnemyStateDead,
	}
	
	state_node = state_map[new_state].new(self, data)
	state_node.transition_requested.connect(switch_state)
	state_node.name = ("State: " + str(new_state))
	state = new_state
	add_child(state_node)

func impale(thrown_item: ThrownItem, item_basis : Basis) -> void:
	var state_data : EnemyStateData = EnemyStateData.new().set_thrown_item(thrown_item).set_thrown_item_basis(item_basis)
	switch_state(State.IMPALED, state_data)
