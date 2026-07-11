extends Node3D
class_name EquipmentComponent

const EQUIPPED_ITEM_PREFAB := preload("uid://dcdd2kn8n007y")

@export var weapon_data: WeaponData
@export var hand_slot : Node3D

func _ready() -> void:
	if weapon_data != null:
		equip_weapon(weapon_data)


func equip_weapon(data: WeaponData, pickup_transform: Transform3D = Transform3D.IDENTITY) -> void:
	weapon_data = data.duplicate()
	var weapon := EQUIPPED_ITEM_PREFAB.instantiate() as EquippedItem
	weapon.weapon_data = weapon_data
	hand_slot.add_child(weapon)
	if pickup_transform != Transform3D.IDENTITY:
		weapon.global_transform = pickup_transform
		animate_to_hand(weapon)

func animate_to_hand(equipped_item: Node3D) -> void:
	var tween := equipped_item.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(equipped_item, "position", Vector3.ZERO, 0.4)
	tween.parallel().tween_property(equipped_item, "rotation", Vector3.ZERO, 0.2)
