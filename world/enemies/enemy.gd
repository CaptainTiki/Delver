extends CharacterBody3D
class_name Enemy

const EQUIPPED_ITEM_PREFAB := preload("uid://dcdd2kn8n007y")

const IMPALE_INTENSITY : float = 100
const RAGDOLL_SIMULATION_TIME : float = 3.0

@onready var physical_bone_torso: PhysicalBone3D = %"Physical Bone Torso"
@onready var collision_shape: CollisionShape3D = %CollisionShape
@onready var skeleton_simulator: PhysicalBoneSimulator3D = %PhysicalBoneSimulator3D
@onready var animation_player: AnimationPlayer = $player/AnimationPlayer

func impale(thrown_item: ThrownItem, item_basis : Basis) -> void:
	var impaled_item := EQUIPPED_ITEM_PREFAB.instantiate() as EquippedItem
	impaled_item.weapon_data = thrown_item.weapon_data
	physical_bone_torso.add_child(impaled_item)
	impaled_item.global_transform.basis = item_basis
	impaled_item.translate_object_local(impaled_item.weapon_data.impale_local_translation)
	impaled_item.rotate_object_local(Vector3.UP, impaled_item.weapon_data.impale_local_rotation)
	thrown_item.queue_free()
	register_death(item_basis * Vector3.FORWARD * IMPALE_INTENSITY + Vector3.UP * IMPALE_INTENSITY)

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
