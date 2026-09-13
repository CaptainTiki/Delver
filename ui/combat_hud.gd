extends CanvasLayer

var health_bar: ProgressBar
var stamina_bar: ProgressBar
var status: Label
var reach_hint: Label

func _ready() -> void:
	reach_hint = Label.new()
	reach_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reach_hint.position = Vector2(-180, 30)
	reach_hint.size = Vector2(360, 70)
	reach_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reach_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reach_hint)
	var box := VBoxContainer.new()
	box.position = Vector2(24, 24)
	box.custom_minimum_size.x = 310
	add_child(box)
	var title := Label.new()
	title.text = "DELVER  /  Combat prototype"
	box.add_child(title)
	health_bar = make_bar(box, "Health", Color(0.75, 0.2, 0.2))
	stamina_bar = make_bar(box, "Stamina", Color(0.25, 0.7, 0.4))
	status = Label.new()
	box.add_child(status)
	var controls := Label.new()
	controls.text = "WASD Move   •   LMB Swing   •   RMB Hold guard\nQ Dodge   •   E Pick up   •   R Throw\nGuard protects your front. Lower it to recover stamina."
	box.add_child(controls)

func make_bar(box: VBoxContainer, caption: String, color: Color) -> ProgressBar:
	var label := Label.new()
	label.text = caption
	box.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(310, 20)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	return bar

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(player):
		return
	var target := player.melee_target() if player.equipment.has_weapon() else null
	reach_hint.text = "CLOSE RANGE" if target != null else ""
	reach_hint.modulate = Color(0.4, 1.0, 0.5)
	if player.feedback_time > 0.0:
		reach_hint.text += "\n" + player.feedback
	if player.health.is_dead():
		reach_hint.text = "You died — R to retry"
	health_bar.max_value = player.health.max_life
	health_bar.value = player.health.current_life
	stamina_bar.max_value = player.max_stamina
	stamina_bar.value = player.stamina
	if player.health.is_dead():
		status.text = "You died — press R to retry"
	elif player.feedback_time > 0.0:
		status.text = player.feedback
	elif player.state == Player.State.BLOCKING:
		status.text = "GUARDING"
	elif player.can_pickup_object():
		status.text = "E — Pick up " + player.current_pickable_focused_item.weapon_data.name
	else:
		status.text = ""
