extends PlayerState
class_name PlayerStateSlashing

# Each cut starts from the previous cut's follow-through, not from idle.
const DURATIONS := [0.58, 0.54, 0.78]
const COMMIT := [0.38, 0.36, 0.58]
const WINDUP := [0.16, 0.10, 0.22]
const CONTACT_END := [0.32, 0.28, 0.40]
const PREP_POS := [Vector3(0.34, -0.12, -0.22), Vector3(-0.26, -0.36, -0.38), Vector3(0.18, 0.0, -0.22)]
const END_POS := [Vector3(-0.26, -0.36, -0.38), Vector3(0.32, -0.18, -0.32), Vector3(-0.06, -0.48, -0.46)]
const PREP_DIR := [Vector3(0.65, 0.65, -0.4), Vector3(-0.8, -0.2, -0.5), Vector3(0.12, 0.85, -0.4)]
const END_DIR := [Vector3(-0.8, -0.2, -0.5), Vector3(0.75, 0.35, -0.5), Vector3(-0.15, -0.65, -0.7)]
var elapsed: float = 0.0
var cut: int = 0
var queued: bool = false
var hit_checked: bool = false
var skeleton: Skeleton3D
var upper: int
var lower: int
var wrist: int
var start_pose: Transform3D
var ready_pose: Transform3D
var previous_pose: Transform3D

func _enter_tree() -> void:
	player.animation_player.pause()
	skeleton = player.get_node("player/Armature/Skeleton3D")
	upper = skeleton.find_bone("UpperArm.R")
	lower = skeleton.find_bone("LowerArm.R")
	wrist = skeleton.find_bone("LowerArm.R_leaf")
	ready_pose = player.camera.global_transform.affine_inverse() * player.equipment.hand_slot.global_transform
	start_pose = ready_pose
	previous_pose = player.equipment.hand_slot.global_transform

func queue_followup() -> void:
	# Only the last 220 ms before the branch point accepts one further attack.
	if cut < 2 and elapsed >= COMMIT[cut] - 0.22 and elapsed < DURATIONS[cut] - 0.1:
		queued = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("action"):
		queue_followup()

func pose_at(position: Vector3, direction: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(direction.normalized(), Vector3.UP), position)

func _physics_process(delta: float) -> void:
	var before := elapsed
	elapsed += delta
	var prep := pose_at(PREP_POS[cut], PREP_DIR[cut])
	var finish := pose_at(END_POS[cut], END_DIR[cut])
	var pose: Transform3D
	if elapsed < WINDUP[cut]:
		pose = start_pose.interpolate_with(prep, smoothstep(0.0, WINDUP[cut], elapsed))
	elif elapsed < CONTACT_END[cut]:
		pose = prep.interpolate_with(finish, smoothstep(WINDUP[cut], CONTACT_END[cut], elapsed))
	elif elapsed < COMMIT[cut]:
		pose = finish
	else:
		pose = finish.interpolate_with(ready_pose, smoothstep(COMMIT[cut], DURATIONS[cut], elapsed))
	var world_pose := player.camera.global_transform * pose
	world_pose = apply_arm_pose(world_pose)
	# Sweep the visible blade over the active cut; one victim per attack.
	if not hit_checked and elapsed >= WINDUP[cut] and before <= CONTACT_END[cut]:
		sweep_blade(previous_pose, world_pose)
	previous_pose = world_pose
	if elapsed >= COMMIT[cut]:
		if Input.is_action_pressed("block"):
			transition_state(Player.State.BLOCKING)
			return
		if Input.is_action_just_pressed("dodge") and player.is_on_floor() and player.spend_stamina(player.dodge_cost):
			transition_state(Player.State.DODGING)
			return
		if queued and cut < 2:
			queued = false
			if player.spend_stamina(player.attack_cost):
				start_pose = pose
				cut += 1
				elapsed = 0.0
				hit_checked = false
				return
	if elapsed >= DURATIONS[cut]:
		transition_state(Player.State.MOVING)

func apply_arm_pose(weapon_pose: Transform3D) -> Transform3D:
	# Two-bone IK keeps the hand attached to the arm while the wrist rolls the blade.
	skeleton.clear_bones_global_pose_override()
	var shoulder := skeleton.get_bone_global_pose(upper)
	var elbow := skeleton.get_bone_global_pose(lower)
	var hand := skeleton.get_bone_global_pose(wrist)
	var target := skeleton.global_transform.affine_inverse() * weapon_pose.origin
	var a := shoulder.origin.distance_to(elbow.origin)
	var b := elbow.origin.distance_to(hand.origin)
	var direction := shoulder.origin.direction_to(target)
	var distance := clampf(shoulder.origin.distance_to(target), 0.05, a + b - 0.001)
	var pole := Vector3(0.8, -1.0, 0.2)
	var bend := (pole - direction * pole.dot(direction)).normalized()
	var along := (a * a - b * b + distance * distance) / (2.0 * distance)
	var joint := shoulder.origin + direction * along + bend * sqrt(maxf(0.0, a * a - along * along))
	var end := shoulder.origin + direction * distance
	shoulder.basis = Basis(Quaternion((elbow.origin - shoulder.origin).normalized(), (joint - shoulder.origin).normalized())) * shoulder.basis
	elbow.basis = Basis(Quaternion((hand.origin - elbow.origin).normalized(), (end - joint).normalized())) * elbow.basis
	elbow.origin = joint
	hand.origin = end
	hand.basis = skeleton.global_basis.inverse() * weapon_pose.basis * player.equipment.hand_slot.basis.inverse()
	skeleton.set_bone_global_pose_override(upper, shoulder, 1.0, true)
	skeleton.set_bone_global_pose_override(lower, elbow, 1.0, true)
	skeleton.set_bone_global_pose_override(wrist, hand, 1.0, true)
	# Use the reachable hand position for damage too.
	weapon_pose.origin = skeleton.to_global(end)
	return weapon_pose

func sweep_blade(from_pose: Transform3D, to_pose: Transform3D) -> void:
	var length: float = 0.97 if player.equipment.weapon_data.name == "Sword" else 0.7
	for step in range(1, 9):
		var pose := from_pose.interpolate_with(to_pose, step / 8.0)
		var query := PhysicsRayQueryParameters3D.create(pose.origin, pose.origin - pose.basis.z * length, 5, [player.get_rid()])
		var result := player.get_world_3d().direct_space_state.intersect_ray(query)
		if result and result.collider is Enemy:
			var enemy := result.collider as Enemy
			if enemy.state in [Enemy.State.DEAD, Enemy.State.DYING, Enemy.State.IMPALED]:
				continue
			hit_checked = true
			var damage := player.equipment.weapon_data.get_damage_delt()
			enemy.try_receive_hit(player, damage + (2 if cut == 2 else 0))
			player.show_feedback("Heavy cut" if cut == 2 else "Connected")
			return

func _exit_tree() -> void:
	if is_instance_valid(skeleton):
		skeleton.clear_bones_global_pose_override()
