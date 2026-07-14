extends Resource
class_name WeaponData


@export var name: String = "DefaultName"
@export var condition: int = 1
@export var max_condition: int = -1 #negative 1 will never degrade
@export var damage_min: int = 1
@export var damage_max: int = 1
@export var impale_local_translation: Vector3
@export var impale_local_rotation: float
@export var reach: float = 1.0
@export var throw_rotation_speed : float = 1.0
@export var throw_movement_speed : float = 1.0
@export var glb_mesh: PackedScene

func get_damage_delt() -> int:
	return randi_range(damage_min, damage_max)

func decrease_condition(amount: int) -> void:
	if max_condition < 0: #if condition is -1, no condition loss
		return
	condition = clampi(condition - amount, 0, max_condition)
