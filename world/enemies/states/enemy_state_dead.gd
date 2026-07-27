extends EnemyState
class_name EnemyStateDead

func _enter_tree() -> void:
	for child in enemy.skeleton_simulator.get_children():
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
